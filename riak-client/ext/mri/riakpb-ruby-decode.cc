#include <ruby.h>
#include "riakclient.pb.h"
#include <arpa/inet.h>
#include <string>

extern "C" {
#include "riakpb-ruby.h"
  extern VALUE cTCPSocket;
  extern VALUE ivar_socket;
  extern VALUE eFailedRequest;
}

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
    case GetResp:
      return INT2FIX(404);
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
    case GetResp:
      return rpb_decode_get(str);
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

VALUE rpb_decode_get_client_id(VALUE string){
  RpbGetClientIdResp res = RpbGetClientIdResp();
  DecodeProtobuff(res, string);
  if(res.has_client_id())
    return rb_str_new2(res.client_id().c_str());
  else
    return Qnil;
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


VALUE rpb_decode_get(VALUE string){
  RpbGetResp res = RpbGetResp();
  VALUE obj, values, contents, links, link, usermeta;
  int i,j,k;
  DecodeProtobuff(res, string);

  obj = rb_hash_new();
  if(res.has_vclock()){
    rb_hash_aset(obj, rb_str_new2("vclock"), rb_str_new2(res.vclock().c_str()));
  }
  values = rb_ary_new2(res.content_size());
  rb_hash_aset(obj, rb_str_new2("values"), values);
  for(i = 0; i < res.content_size(); i++){
    contents = rb_hash_new();
    rb_ary_push(values, contents);
    rb_hash_aset(contents, rb_str_new2("data"), rb_str_new2(res.content(i).value().c_str()));
    if(res.content(i).has_content_type()){
      rb_hash_aset(contents, rb_str_new2("content-type"), rb_str_new2(res.content(i).content_type().c_str()));
    }
    if(res.content(i).has_charset()){
      rb_hash_aset(contents, rb_str_new2("charset"), rb_str_new2(res.content(i).charset().c_str()));
    }
    if(res.content(i).has_content_encoding()){
      rb_hash_aset(contents, rb_str_new2("encoding"), rb_str_new2(res.content(i).content_encoding().c_str()));
    }
    if(res.content(i).has_vtag()){
      rb_hash_aset(contents, rb_str_new2("vtag"), rb_str_new2(res.content(i).vtag().c_str()));
    }
    if(res.content(i).has_last_mod()){
      rb_hash_aset(contents, rb_str_new2("last-modified"), UINT2NUM(res.content(i).last_mod()));
    }
    if(res.content(i).has_last_mod_usecs()){
      rb_hash_aset(contents, rb_str_new2("last-modified-usecs"), UINT2NUM(res.content(i).last_mod_usecs()));
    }
    links = rb_ary_new2(res.content(i).links_size());
    rb_hash_aset(contents, rb_str_new2("links"), links);
    for(j = 0; j < res.content(i).links_size(); j++){
      link = rb_hash_new();
      rb_ary_push(links, link);
      if(res.content(i).links(j).has_bucket()){
        rb_hash_aset(link, rb_str_new2("bucket"), rb_str_new2(res.content(i).links(j).bucket().c_str()));
      }
      if(res.content(i).links(j).has_key()){
        rb_hash_aset(link, rb_str_new2("key"), rb_str_new2(res.content(i).links(j).key().c_str()));
      }
      if(res.content(i).links(j).has_tag()){
        rb_hash_aset(link, rb_str_new2("tag"), rb_str_new2(res.content(i).links(j).tag().c_str()));
      }
    }
    usermeta = rb_hash_new();
    rb_hash_aset(contents, rb_str_new2("meta"), usermeta);
    for(k = 0; k < res.content(i).usermeta_size(); k++){
      if(res.content(i).usermeta(k).has_value())
        rb_hash_aset(usermeta, rb_str_new2(res.content(i).usermeta(k).key().c_str()), rb_str_new2(res.content(i).usermeta(k).value().c_str()));
      else
        rb_hash_aset(usermeta, rb_str_new2(res.content(i).usermeta(k).key().c_str()), Qnil);
    }
  }
  return obj;
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
