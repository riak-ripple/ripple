#include <ruby.h>
#include "riakclient.pb.h"
#include <arpa/inet.h>
#include <string>

// We're using google's protobufs, so we have to compile in C++. MRI
// is in C, so we need C calling conventions in our extension
// functions for it all to hook up.
extern "C" {
#include "riakpb-ruby.h"
  VALUE cTCPSocket;
  VALUE ivar_socket;
  VALUE eFailedRequest;
  VALUE mJSON;

  VALUE rpb_ping(VALUE self){
    WriteProtobuff(SOCKET, PingReq, NULL);
    return rpb_decode_response(self);
  }

  VALUE rpb_get_client_id(VALUE self){
    WriteProtobuff(SOCKET, GetClientIdReq, NULL);
    return rpb_decode_response(self);
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

  VALUE rpb_get(int argc, VALUE *argv, VALUE self){
    RpbGetReq req = RpbGetReq();
    VALUE bucket, key, r;
    rb_scan_args(argc, argv, "21", &bucket, &key, &r);
    bucket = rb_funcall(bucket, rb_intern("to_s"), 0);
    key = rb_funcall(key, rb_intern("to_s"), 0);
    req.set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
    req.set_key((void*)RSTRING_PTR(key), (size_t)RSTRING_LEN(key));
    if(!NIL_P(r)){
      req.set_r(QuorumValue(r));
    }
    WriteProtobuff(SOCKET, GetReq, &req);
    return rpb_decode_response(self);
  }

  VALUE rpb_put(int argc, VALUE *argv, VALUE self){
    VALUE robject, w, dw, returnbody; // inputs
    VALUE data, links, link, keys, metak, metav,
      vclock, ctype, meta, bucket, key, tag; // internal uses
    RpbPutReq *req = new RpbPutReq();
    RpbContent *content = req->mutable_content();
    RpbPair *pair;
    RpbLink *pblink;
    rb_scan_args(argc, argv, "13", &robject, &returnbody, &w, &dw);

    // Set bucket, key, w, dw, returnbody
    bucket = rb_funcall(rb_funcall(robject, rb_intern("bucket"), 0), rb_intern("name"), 0);
    key = rb_funcall(robject, rb_intern("key"), 0);
    req->set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
    req->set_key((void*)RSTRING_PTR(key), (size_t)RSTRING_LEN(key));
    if(!NIL_P(w))
      req->set_w(QuorumValue(w));
    if(!NIL_P(dw))
      req->set_dw(QuorumValue(dw));
    if(RTEST(returnbody))
      req->set_return_body(1);

    // Set vclock if present. For now Base64-decode it, until we do
    // it in the client backend.
    vclock = rb_funcall(robject, rb_intern("vclock"), 0);
    vclock = rb_funcall(rb_const_get(rb_cObject, rb_intern("Base64")), rb_intern("decode64"), 1, vclock);
    if(!NIL_P(vclock))
      req->set_vclock((void*)RSTRING_PTR(vclock), (size_t)RSTRING_LEN(vclock));

    // Set the data
    data = rb_funcall(robject, rb_intern("raw_data"), 0);
    content->set_value((void*)RSTRING_PTR(data), (size_t)RSTRING_LEN(data));

    // Set content type if present
    ctype = rb_funcall(robject, rb_intern("content_type"), 0);
    if(!NIL_P(ctype))
      content->set_content_type((void*)RSTRING_PTR(ctype), (size_t)RSTRING_LEN(ctype));

    // Set user meta
    meta = rb_funcall(robject, rb_intern("meta"), 0);
    if(!NIL_P(meta)){
      keys = rb_funcall(meta, rb_intern("keys"), 0);
      while(!NIL_P(metak = rb_ary_shift(keys))){
        pair = content->add_usermeta();
        metav = rb_funcall(rb_hash_aref(meta, metak), rb_intern("to_s"), 0);
        pair->set_key((void*)RSTRING_PTR(metak), (size_t)RSTRING_LEN(metak));
        pair->set_value((void*)RSTRING_PTR(metav), (size_t)RSTRING_LEN(metav));
      }
    }

    // Set links
    links = rb_funcall(rb_funcall(robject, rb_intern("links"), 0), rb_intern("to_a"), 0);
    if(!NIL_P(links) && !RTEST(rb_funcall(links, rb_intern("empty?"), 0))){
      while(!NIL_P(link = rb_ary_shift(links))){
        if(NIL_P(rb_funcall(link, rb_intern("key"), 0)))
          continue;
        pblink = content->add_links();
        bucket = rb_funcall(link, rb_intern("bucket"), 0);
        key = rb_funcall(link, rb_intern("key"), 0);
        tag = rb_funcall(link, rb_intern("tag"), 0);
        pblink->set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
        pblink->set_key((void*)RSTRING_PTR(key), (size_t)RSTRING_LEN(key));
        pblink->set_tag((void*)RSTRING_PTR(tag), (size_t)RSTRING_LEN(tag));
      }
    }

    WriteProtobuff(SOCKET, PutReq, req);
    return rpb_decode_response(self);
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

  VALUE rpb_list_keys(VALUE self, VALUE bucket){
    RpbListKeysReq req = RpbListKeysReq();
    bucket = rb_funcall(bucket, rb_intern("to_s"), 0);
    req.set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
    WriteProtobuff(SOCKET, ListKeysReq, &req);
    return rpb_decode_response(self);
  }

  VALUE rpb_get_bucket(VALUE self, VALUE bucket){
    RpbGetBucketReq req = RpbGetBucketReq();
    bucket = rb_funcall(bucket, rb_intern("to_s"), 0);
    req.set_bucket((void*)RSTRING_PTR(bucket), (size_t)RSTRING_LEN(bucket));
    WriteProtobuff(SOCKET, GetBucketReq, &req);
    return rpb_decode_response(self);
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

  VALUE rpb_mapred(VALUE self, VALUE json){
    RpbMapRedReq req = RpbMapRedReq();
    VALUE ctype = rb_str_new2("application/json");
    req.set_content_type((void*)RSTRING_PTR(ctype), (size_t)RSTRING_LEN(ctype));
    req.set_request((void*)RSTRING_PTR(json), (size_t)RSTRING_LEN(json));
    WriteProtobuff(SOCKET, MapRedReq, &req);
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
    mJSON = rb_const_get(rb_const_get(rb_cObject, rb_intern("ActiveSupport")), rb_intern("JSON"));

    rb_define_method(mProtobufs, "initialize", RUBY_METHOD_FUNC(rpb_init), 1);
    rb_define_method(mProtobufs, "ping", RUBY_METHOD_FUNC(rpb_ping), 0);
    rb_define_method(mProtobufs, "get_client_id", RUBY_METHOD_FUNC(rpb_get_client_id), 0);
    rb_alias(mProtobufs, rb_intern("client_id"), rb_intern("get_client_id"));
    rb_define_method(mProtobufs, "set_client_id", RUBY_METHOD_FUNC(rpb_set_client_id), 1);
    rb_alias(mProtobufs, rb_intern("client_id="), rb_intern("set_client_id"));
    rb_define_method(mProtobufs, "get_server_info", RUBY_METHOD_FUNC(rpb_get_server_info), 0);
    rb_define_method(mProtobufs, "get", RUBY_METHOD_FUNC(rpb_get), -1);
    rb_define_method(mProtobufs, "put", RUBY_METHOD_FUNC(rpb_put), -1);
    rb_define_method(mProtobufs, "delete", RUBY_METHOD_FUNC(rpb_delete), -1);
    rb_define_method(mProtobufs, "list_buckets", RUBY_METHOD_FUNC(rpb_list_buckets), 0);
    rb_define_method(mProtobufs, "list_keys", RUBY_METHOD_FUNC(rpb_list_keys), 1);
    rb_define_method(mProtobufs, "get_bucket", RUBY_METHOD_FUNC(rpb_get_bucket), 1);
    rb_define_method(mProtobufs, "set_bucket", RUBY_METHOD_FUNC(rpb_set_bucket), 2);
    rb_define_method(mProtobufs, "mapred", RUBY_METHOD_FUNC(rpb_mapred), 1);
  }
}
