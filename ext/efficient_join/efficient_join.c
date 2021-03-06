#include "efficient_join.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

struct strbuf_t {
    char *buf;
    size_t pos;
    size_t len;
};

static struct strbuf_t strbuf_new(size_t initial_size) {
    struct strbuf_t strbuf = { (char *)malloc(initial_size), 0, initial_size };
    return strbuf;
}

static void strbuf_free(struct strbuf_t *strbuf) {
    free(strbuf->buf);
}

static inline void strbuf_expand(struct strbuf_t *strbuf, size_t min_size) {
    strbuf->buf = (char *)realloc(strbuf->buf, min_size > strbuf->len * 2 ? min_size : strbuf->len * 2);
    strbuf->len *= 2;
}

static inline void strbuf_write_str(struct strbuf_t *strbuf, const char *str, size_t len)
{
    if (strbuf->len < strbuf->pos + len) {
        strbuf_expand(strbuf, strbuf->pos + len);
    }

    memcpy(strbuf->buf + strbuf->pos, str, len);
    strbuf->pos += len;
}

static inline void strbuf_write_int64(struct strbuf_t *strbuf, int64_t value)
{
    int bytes_written;
   
    // 22: maximum length of string representation of 64-bit int
    if (strbuf->len <= strbuf->pos + 22) {
        strbuf_expand(strbuf, strbuf->pos + 22);
    }

    bytes_written = snprintf(strbuf->buf + strbuf->pos, 22, "%ld", value);
    strbuf->pos += bytes_written;
}

VALUE rb_efficient_join(VALUE self, VALUE _header, VALUE _footer, VALUE _item_prefix, VALUE _item_suffix, VALUE _join, VALUE number_array) {
    VALUE out;
    const long array_len = RARRAY_LEN(number_array);
    const char* header = StringValuePtr(_header);
    const char* footer = StringValuePtr(_footer);
    const char* item_prefix = StringValuePtr(_item_prefix);
    const char* item_suffix = StringValuePtr(_item_suffix);
    const char* join = StringValuePtr(_join);
    VALUE *c_array = RARRAY_PTR(number_array);
    const size_t prefix_len = RSTRING_LEN(_item_prefix);
    const size_t suffix_len = RSTRING_LEN(_item_suffix);
    const size_t join_len = RSTRING_LEN(_join);

    struct strbuf_t join_buf = strbuf_new(suffix_len + join_len + prefix_len);
    // estimate likely maximum buffer size, to avoid reallocs
    struct strbuf_t buf = strbuf_new((array_len + 1) * (join_buf.pos + 10));

    // build joining string
    strbuf_write_str(&join_buf, item_suffix, suffix_len);
    strbuf_write_str(&join_buf, join, join_len);
    strbuf_write_str(&join_buf, item_prefix, prefix_len);

    strbuf_write_str(&buf, header, RSTRING_LEN(_header));
    strbuf_write_str(&buf, item_prefix, prefix_len);

    for (long i=0; i<array_len; ++i) {
        VALUE v = c_array[i];

        switch (TYPE(v)) {
            case T_FIXNUM:
                strbuf_write_int64(&buf, FIX2LONG(v));
                break;
            case T_BIGNUM:
                strbuf_write_int64(&buf, rb_big2ll(v));
                break;
            case T_STRING:
                strbuf_write_str(&buf, StringValuePtr(v), RSTRING_LEN(v));
                break;
            default:
                // rb_raise does not return control, so clean up first
                strbuf_free(&join_buf);
                strbuf_free(&buf);
                rb_raise(rb_eTypeError, "array must contain only strings and integers");
        }

        if (i < array_len - 1) {
            strbuf_write_str(&buf, join_buf.buf, join_buf.pos);
        }
    }
    strbuf_write_str(&buf, item_suffix, suffix_len);
    strbuf_write_str(&buf, footer, RSTRING_LEN(_footer));

    out = rb_str_new(buf.buf, buf.pos);

    strbuf_free(&join_buf);
    strbuf_free(&buf);

    return out;
}

void Init_efficient_join()
{
    VALUE mod = rb_define_module("EfficientJoinCExt");

    rb_define_method(mod, "_join", rb_efficient_join, 6);
}
