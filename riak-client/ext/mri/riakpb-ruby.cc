#include <ruby.h>
#include "riakclient.pb.h"
#include <arpa/inet.h>
#include <string>

// We're using google's protobufs, so we have to compile in C++. MRI
// is in C, so we need C calling conventions in our extension
// functions for it all to hook up.
extern "C" {
#include "riakpb-ruby.h"
  static VALUE cTCPSocket;
  static VALUE ivar_socket;
  static VALUE eFailedRequest;

  VALUE rpb_decode_response(VALUE self){
    VALUE str, socket;
    uint32_t msglen;
    uint8_t msgcode;
    socket = SOCKET;
    str = ReadSocket(socket, 5);
    msglen = ntohl(((uint32_t*)RSTRING_PTR(str))[0]) - 1;
    msgcode = (uint8_t)(RSTRING_PTR(str)[4]);
    if(msglen == 0){
      switch(msgcode){
      case PingResp: case SetClientIdResp: case PutResp : case DelResp: case SetBucketResp:
        return Qtrue;
        break;
      case ListBucketsResp: case ListKeysResp:
        return rb_ary_new();
        break;
      default:
        return Qfalse;
        break;
      }
    } else {
      str = ReadSocket(socket, msglen);
      switch(msgcode){
      case ErrorResp:
        return rpb_decode_error(str);
        break;
      case GetClientIdResp:
        return rpb_decode_get_client_id(str);
        break;
      case GetServerInfoResp:
        return rpb_decode_get_server_info(str);
        break;
      case ListBucketsResp:
        return rpb_decode_list_buckets(str);
        break;
      case ListKeysResp:
        return rpb_decode_list_keys(str, socket);
        break;
      case GetBucketResp:
        return rpb_decode_get_bucket(str);
        break;
      default:
        break;
      }
    }
    return Qnil;
  }

  // raises Riak::FailedRequest(method, code, expected, headers, body)
  VALUE rpb_decode_error(VALUE string){
    RpbErrorResp res = RpbErrorResp();
    VALUE err, args[5];
    DecodeProtobuff(res, string);
    args[0] = rb_intern("pb");
    args[1] = rb_str_new2("ok");
    args[2] = (res.has_errcode()) ? UINT2NUM(res.errcode()) : INT2FIX(0);
    args[3] = rb_hash_new();
    args[4] = (res.has_errmsg()) ? rb_str_new2(res.errmsg().c_str()) : rb_str_new2("failed");
    err = rb_class_new_instance(5, args, eFailedRequest);
    rb_exc_raise(err);
  }

  VALUE rpb_ping(VALUE self){
    WriteProtobuff(SOCKET, PingReq, NULL);
    return rpb_decode_response(self);
  }

  VALUE rpb_get_client_id(VALUE self){
    WriteProtobuff(SOCKET, GetClientIdReq, NULL);
    return rpb_decode_response(self);
  }

  VALUE rpb_decode_get_client_id(VALUE string){
    RpbGetClientIdResp res = RpbGetClientIdResp();
    DecodeProtobuff(res, string);
    if(res.has_client_id())
      return rb_str_new2(res.client_id().c_str());
    else
      return Qnil;
  }

  VALUE rpb_set_client_id(VALUE self, VALUE id){
    RpbSetClientIdReq req = RpbSetClientIdReq();
    id = rb_funcall(id, rb_intern("to_s"), 0);
    req.set_client_id((void*)RSTRING_PTR(id), (size_t)RSTRING_LEN(id));
    WriteProtobuff(SOCKET, SetClientIdReq, &req);
    return rpb_decode_response(self);
  }

  VALUE rpb_get_server_info(VALUE self){
    WriteProtobuff(SOCKET, GetServerInfoReq, NULL);
    return rpb_decode_response(self);
  }

  VALUE rpb_decode_get_server_info(VALUE string){
    RpbGetServerInfoResp res = RpbGetServerInfoResp();
    VALUE hash = rb_hash_new();
    DecodeProtobuff(res, string);
    if(res.has_node())
      rb_hash_aset(hash, rb_str_new2("node"), rb_str_new2(res.node().c_str()));
    if(res.has_server_version())
      rb_hash_aset(hash, rb_str_new2("server_version"), rb_str_new2(res.server_version().c_str()));
    return hash;
  }

  VALUE rpb_delete(int argc, VALUE *argv, VALUE self){
    RpbDelReq req = RpbDelReq();
    VALUE bucket, key, rw;
    rb_scan_args(argc, argv, "21", &bucket, &key, &rw);
    bucket = rb_funcall(bucket, rb_intern("to_s"), 0);
    key = rb_funcall(key, rb_intern("to_s"), 0);
    req.set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
    req.set_key((void*)RSTRING_PTR(key), (size_t)RSTRING_LEN(key));
    if(!NIL_P(rw)) {
      req.set_rw(QuorumValue(rw));
    }
    WriteProtobuff(SOCKET, DelReq, &req);
    return rpb_decode_response(self);
  }

  VALUE rpb_list_buckets(VALUE self){
    WriteProtobuff(SOCKET, ListBucketsReq, NULL);
    return rpb_decode_response(self);
  }

  VALUE rpb_decode_list_buckets(VALUE string){
    RpbListBucketsResp res = RpbListBucketsResp();
    VALUE ary;
    int i;
    DecodeProtobuff(res, string);
    ary = rb_ary_new2((long)res.buckets_size());
    for(i = 0; i < res.buckets_size(); i++){
      rb_ary_push(ary, rb_str_new2(res.buckets(i).c_str()));
    }
    return ary;
  }

  VALUE rpb_list_keys(VALUE self, VALUE bucket){
    RpbListKeysReq req = RpbListKeysReq();
    bucket = rb_funcall(bucket, rb_intern("to_s"), 0);
    req.set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
    WriteProtobuff(SOCKET, ListKeysReq, &req);
    return rpb_decode_response(self);
  }

  VALUE rpb_decode_list_keys(VALUE string, VALUE socket){
    RpbListKeysResp res = RpbListKeysResp();
    bool done = 0;
    VALUE list = rb_ary_new(), prolog;
    int i;
    uint32_t msglen;
    uint8_t msgcode;
    while(!done){
      DecodeProtobuff(res, string);
      done = res.has_done() && res.done();
      for(i = 0; i < res.keys_size(); i++) {
        rb_ary_push(list, rb_str_new2(res.keys(i).c_str()));
      }
      if(rb_block_given_p()){
        rb_yield(list);
        list = rb_ary_new();
      }
      if(!done) {
        res.Clear(); // reuse the pbuf
        prolog = ReadSocket(socket, 5);
        msglen = ntohl(((uint32_t*)RSTRING_PTR(prolog))[0]) - 1;
        msgcode = (uint8_t)(RSTRING_PTR(prolog)[4]);
        string = ReadSocket(socket, msglen);
        if(msgcode == ErrorResp)
          rpb_decode_error(string);
        else if(msgcode != ListKeysResp) // TODO: throw an exception, don't exit
          rb_fatal("Unexpected response code from list_keys operation: %d", msgcode);
      }
    }
    return list;
  }

  VALUE rpb_get_bucket(VALUE self, VALUE bucket){
    RpbGetBucketReq req = RpbGetBucketReq();
    bucket = rb_funcall(bucket, rb_intern("to_s"), 0);
    req.set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
    WriteProtobuff(SOCKET, GetBucketReq, &req);
    return rpb_decode_response(self);
  }

  VALUE rpb_decode_get_bucket(VALUE string){
    RpbGetBucketResp res;
    VALUE hash;
    hash = rb_hash_new();
    res = RpbGetBucketResp();
    DecodeProtobuff(res, string);
    if(res.has_props()){
      if(res.props().has_n_val())
        rb_hash_aset(hash, rb_str_new2("n_val"), UINT2NUM(res.props().n_val()));
      if(res.props().has_allow_mult())
        rb_hash_aset(hash, rb_str_new2("allow_mult"), (res.props().allow_mult()) ? Qtrue : Qfalse);
    }
    return hash;
  }

  VALUE rpb_set_bucket(VALUE self, VALUE bucket, VALUE hash){
    RpbSetBucketReq req;
    VALUE allow_mult, n_val;
    if(TYPE(hash) != T_HASH)
      rb_raise(rb_eArgError, "bucket props must be a hash");
    req = RpbSetBucketReq();
    bucket = rb_funcall(bucket, rb_intern("to_s"), 0);
    rb_funcall(hash, rb_intern("stringify_keys!"), 0);
    allow_mult = rb_hash_aref(hash, rb_str_new2("allow_mult"));
    n_val = rb_hash_aref(hash, rb_str_new2("n_val"));

    req.set_bucket((void*)RSTRING_PTR(bucket),(size_t)RSTRING_LEN(bucket));
    if(!NIL_P(allow_mult))
      req.mutable_props()->set_allow_mult(RTEST(allow_mult) ? 1 : 0);
    if(!NIL_P(n_val) && FIXNUM_P(n_val))
      req.mutable_props()->set_n_val(FIX2UINT(n_val));
    WriteProtobuff(SOCKET, SetBucketReq, &req);
    return rpb_decode_response(self);
  }

  // TODO: This might should be done in Ruby, not getting any benefit from C.
  VALUE rpb_init(VALUE self, VALUE client){
    VALUE socket, host, port;
    rb_ivar_set(self, rb_intern("@client"), client);
    host = rb_ivar_get(client, rb_intern("@host"));
    port = rb_ivar_get(client, rb_intern("@pb_port"));
    socket = rb_funcall(cTCPSocket, rb_intern("new"), 2, host, port);
    rb_ivar_set(self, ivar_socket, socket);
    // Here we might want to open Protobuf-specific streams or do
    // other initialization. TBD
  }

  void Init_riakpb()
  {
    VALUE mProtobufs, cRiakClient;
    rb_require("socket");
    ivar_socket = rb_intern("@socket");
    cTCPSocket = rb_const_get(rb_cObject, rb_intern("TCPSocket"));
    cRiakClient = rb_define_module("Riak");
    eFailedRequest = rb_const_get(cRiakClient, rb_intern("FailedRequest"));
    cRiakClient = rb_define_class_under(cRiakClient, "Client", rb_cObject);
    mProtobufs = rb_define_module_under(cRiakClient, "Protobufs");
    rb_define_method(mProtobufs, "initialize", RUBY_METHOD_FUNC(rpb_init), 1);
    rb_define_method(mProtobufs, "ping", RUBY_METHOD_FUNC(rpb_ping), 0);
    rb_define_method(mProtobufs, "get_client_id", RUBY_METHOD_FUNC(rpb_get_client_id), 0);
    rb_alias(mProtobufs, rb_intern("client_id"), rb_intern("get_client_id"));
    rb_define_method(mProtobufs, "set_client_id", RUBY_METHOD_FUNC(rpb_set_client_id), 1);
    rb_alias(mProtobufs, rb_intern("client_id="), rb_intern("set_client_id"));
    rb_define_method(mProtobufs, "get_server_info", RUBY_METHOD_FUNC(rpb_get_server_info), 0);
    rb_define_method(mProtobufs, "delete", RUBY_METHOD_FUNC(rpb_delete), -1);
    rb_define_method(mProtobufs, "list_buckets", RUBY_METHOD_FUNC(rpb_list_buckets), 0);
    rb_define_method(mProtobufs, "list_keys", RUBY_METHOD_FUNC(rpb_list_keys), 1);
    rb_define_method(mProtobufs, "get_bucket", RUBY_METHOD_FUNC(rpb_get_bucket), 1);
    rb_define_method(mProtobufs, "set_bucket", RUBY_METHOD_FUNC(rpb_set_bucket), 2);
  }
}
