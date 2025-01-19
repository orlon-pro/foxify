package main

/*
#include "foxify.h"

VALUE rb_foxify_resumable_sha256_init(VALUE self);
VALUE rb_foxify_resumable_sha256_update(VALUE self, VALUE state, VALUE data);
VALUE rb_foxify_resumable_sha256_finalize(VALUE self, VALUE state);
VALUE rb_foxify_resumable_sha1_init(VALUE self);
VALUE rb_foxify_resumable_sha1_update(VALUE self, VALUE state, VALUE data);
VALUE rb_foxify_resumable_sha1_finalize(VALUE self, VALUE state);
*/
import "C"

import (
	"crypto/sha1"
	"crypto/sha256"
	"encoding"
	"encoding/base64"
	"encoding/hex"
	"log"
	"unsafe"

	"github.com/ruby-go-gem/go-gem-wrapper/ruby"
)

//export rb_foxify_resumable_sha256_init
func rb_foxify_resumable_sha256_init(_ C.VALUE) C.VALUE {
	h := sha256.New()

	marshaler := h.(encoding.BinaryMarshaler)
	state, err := marshaler.MarshalBinary()
	if err != nil {
		log.Fatal("Unable to marshal hash:", err)
	}

	enc := base64.StdEncoding.EncodeToString(state)
	return C.VALUE(ruby.String2Value(enc))
}

//export rb_foxify_resumable_sha1_init
func rb_foxify_resumable_sha1_init(_ C.VALUE) C.VALUE {
	h := sha1.New()

	marshaler := h.(encoding.BinaryMarshaler)
	state, err := marshaler.MarshalBinary()
	if err != nil {
		log.Fatal("Unable to marshal hash:", err)
	}

	enc := base64.StdEncoding.EncodeToString(state)
	return C.VALUE(ruby.String2Value(enc))
}

//export rb_foxify_resumable_sha256_update
func rb_foxify_resumable_sha256_update(_ C.VALUE, state C.VALUE, data C.VALUE) C.VALUE {
	s, _ := base64.StdEncoding.DecodeString(ruby.Value2String(ruby.VALUE(state)))
	h := sha256.New()
	unmarshaler := h.(encoding.BinaryUnmarshaler)
	unmarshaler.UnmarshalBinary(s)

	rValue := ruby.VALUE(data)
	rLength := ruby.RSTRING_LENINT(rValue)
	if rLength > 0 {
		char := ruby.RSTRING_PTR(rValue)
		h.Write(C.GoBytes(unsafe.Pointer(char), C.int(rLength)))
	}

	marshaler := h.(encoding.BinaryMarshaler)
	new_state, err := marshaler.MarshalBinary()
	if err != nil {
		log.Fatal("Unable to marshal hash:", err)
	}

	enc := base64.StdEncoding.EncodeToString(new_state)
	return C.VALUE(ruby.String2Value(enc))
}

//export rb_foxify_resumable_sha1_update
func rb_foxify_resumable_sha1_update(_ C.VALUE, state C.VALUE, data C.VALUE) C.VALUE {
	s, _ := base64.StdEncoding.DecodeString(ruby.Value2String(ruby.VALUE(state)))
	h := sha1.New()
	unmarshaler := h.(encoding.BinaryUnmarshaler)
	unmarshaler.UnmarshalBinary(s)

	rValue := ruby.VALUE(data)
	rLength := ruby.RSTRING_LENINT(rValue)
	if rLength > 0 {
		char := ruby.RSTRING_PTR(rValue)
		h.Write(C.GoBytes(unsafe.Pointer(char), C.int(rLength)))
	}

	marshaler := h.(encoding.BinaryMarshaler)
	new_state, err := marshaler.MarshalBinary()
	if err != nil {
		log.Fatal("Unable to marshal hash:", err)
	}

	enc := base64.StdEncoding.EncodeToString(new_state)
	return C.VALUE(ruby.String2Value(enc))
}

//export rb_foxify_resumable_sha256_finalize
func rb_foxify_resumable_sha256_finalize(_ C.VALUE, state C.VALUE) C.VALUE {
	s, _ := base64.StdEncoding.DecodeString(ruby.Value2String(ruby.VALUE(state)))
	h := sha256.New()
	unmarshaler := h.(encoding.BinaryUnmarshaler)
	unmarshaler.UnmarshalBinary(s)

	result := h.Sum(nil)
	return C.VALUE(ruby.String2Value(hex.EncodeToString(result)))
}

//export rb_foxify_resumable_sha1_finalize
func rb_foxify_resumable_sha1_finalize(_ C.VALUE, state C.VALUE) C.VALUE {
	s, _ := base64.StdEncoding.DecodeString(ruby.Value2String(ruby.VALUE(state)))
	h := sha1.New()
	unmarshaler := h.(encoding.BinaryUnmarshaler)
	unmarshaler.UnmarshalBinary(s)

	result := h.Sum(nil)
	return C.VALUE(ruby.String2Value(hex.EncodeToString(result)))
}

//export Init_foxify
func Init_foxify() {
	rb_mFoxify := ruby.RbDefineModule("Foxify")
	rb_mNative := ruby.RbDefineModuleUnder(rb_mFoxify, "Native")

	// SHA256
	ruby.RbDefineSingletonMethod(rb_mNative, "sha256_init", C.rb_foxify_resumable_sha256_init, 0)
	ruby.RbDefineSingletonMethod(rb_mNative, "sha256_update", C.rb_foxify_resumable_sha256_update, 2)
	ruby.RbDefineSingletonMethod(rb_mNative, "sha256_finalize", C.rb_foxify_resumable_sha256_finalize, 1)

	// SHA1
	ruby.RbDefineSingletonMethod(rb_mNative, "sha1_init", C.rb_foxify_resumable_sha1_init, 0)
	ruby.RbDefineSingletonMethod(rb_mNative, "sha1_update", C.rb_foxify_resumable_sha1_update, 2)
	ruby.RbDefineSingletonMethod(rb_mNative, "sha1_finalize", C.rb_foxify_resumable_sha1_finalize, 1)
}

func main() {
}
