
enum RpbMessageCodes {
  ErrorResp,            //
  PingReq,              //
  PingResp,             //
  GetClientIdReq,       //
  GetClientIdResp,      //
  SetClientIdReq,       //
  SetClientIdResp,      //
  GetServerInfoReq,     //
  GetServerInfoResp,    //
  GetReq,
  GetResp,
  PutReq,
  PutResp,
  DelReq,               //
  DelResp,              //
  ListBucketsReq,       //
  ListBucketsResp,      //
  ListKeysReq,          //
  ListKeysResp,         //
  GetBucketReq,         //
  GetBucketResp,        //
  SetBucketReq,         //
  SetBucketResp,        //
  MapRedReq,
  MapRedResp
};

// Symbolic quorums
#define RIAKC_UINT_MAX   0xffffffff
#define RIAKC_RW_ONE     RIAKC_UINT_MAX-1
#define RIAKC_RW_QUORUM  RIAKC_UINT_MAX-2
#define RIAKC_RW_ALL     RIAKC_UINT_MAX-3
#define RIAKC_RW_DEFAULT RIAKC_UINT_MAX-4

// Inlined function to read a string from the Ruby socket
static inline VALUE ReadSocket(VALUE socket, uint32_t len){
  return rb_funcall(socket, rb_intern("read"), 1, UINT2NUM(len));
}

// Decodes a protobuff from a Ruby string
#define DecodeProtobuff(pbuf, str) pbuf.ParseFromArray((void*)RSTRING_PTR(str),(int)RSTRING_LEN(str))

// Writes a given protobuff to the given socket with the specified message code
static inline void WriteProtobuff(VALUE socket, uint8_t msgcode, ::google::protobuf::Message *pbuf){
  uint32_t msglen;
  void *out;
  if(pbuf){
    msglen = (uint32_t)pbuf->ByteSize();
    out = ALLOC_N(uint8_t, msglen);
  } else {
    msglen = 0;
  }
  VALUE tmp = rb_str_buf_new(5+msglen);
  uint8_t prolog[5];
  ((uint32_t*)prolog)[0] = htonl(msglen+1);
  prolog[4] = msgcode;
  rb_str_buf_cat(tmp, (char*)prolog, 5);
  if(pbuf) {
    pbuf->SerializeToArray(out, msglen);
    rb_str_buf_cat(tmp, (char*)out, (long)msglen);
  }
  rb_io_write(socket, tmp);
}

#define StringEqual(rbstr, cstr) (TYPE(q) == T_STRING || TYPE(q) == T_SYMBOL) && rb_str_cmp(rb_funcall(rbstr, rb_intern("to_s"), 0), rb_str_new2(cstr))

static inline uint32_t QuorumValue(VALUE q){
  if(TYPE(q) == T_FIXNUM){
    return (uint32_t)FIX2UINT(q);
  } else if(StringEqual(q,"one")) {
    return RIAKC_RW_ONE;
  } else if(StringEqual(q,"quorum")) {
    return RIAKC_RW_QUORUM;
  } else if(StringEqual(q,"all")) {
    return RIAKC_RW_ALL;
  } else if(StringEqual(q,"default")){
    return RIAKC_RW_DEFAULT;
  } else {
    rb_raise(rb_eArgError, "invalid quorum value: %s", RSTRING_PTR(rb_obj_as_string(q)));
  }
}

#define SOCKET rb_ivar_get(self, ivar_socket)

extern "C" {
  VALUE rpb_decode_error(VALUE);
  VALUE rpb_ping(VALUE);
  VALUE rbp_get_client_id(VALUE);
  VALUE rpb_set_client_id(VALUE, VALUE);
  VALUE rpb_get_server_info(VALUE);
  VALUE rpb_get(int, VALUE*, VALUE);
  VALUE rpb_delete(int, VALUE*, VALUE);
  VALUE rpb_list_buckets(VALUE);
  VALUE rpb_list_keys(VALUE, VALUE);
  VALUE rpb_get_bucket(VALUE, VALUE);
  VALUE rpb_set_bucket(VALUE, VALUE, VALUE);
  VALUE rpb_init(VALUE, VALUE);
}

VALUE rpb_decode_response(VALUE);
VALUE rpb_decode_get_client_id(VALUE);
VALUE rpb_decode_get_server_info(VALUE);
VALUE rpb_decode_get(VALUE);
VALUE rpb_decode_list_buckets(VALUE);
VALUE rpb_decode_list_keys(VALUE, VALUE);
VALUE rpb_decode_get_bucket(VALUE);
