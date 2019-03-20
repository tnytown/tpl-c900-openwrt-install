package main

import (
	"fmt"
	"crypto/aes"
	"crypto/cipher"
	"encoding/hex"
	"io/ioutil"
	"io"
	"bytes"
	"compress/zlib"
	"os"
	"flag"
)

func main() {
	var (
		err error

		inName = flag.String("in", "", "input file")
		outName = flag.String("out", "", "output file")
	)
	flag.Parse()

	in, err := os.Open(*inName)
	check(err)
	out, err := os.OpenFile(*outName, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	check(err)

	var inB, outB []byte
	enc := false
	if flag.Arg(0) == "enc" || flag.Arg(0) == "dec" {
		enc = true
		inB, _ = ioutil.ReadAll(in)
		if flag.Arg(0) == "enc" {
			inB = pad(16, inB)
		}
		outB = make([]byte, len(inB))
	}

	var (
		key = mustDecodeHexString(os.ExpandEnv("$KEY"))
		iv = mustDecodeHexString(os.ExpandEnv("$IV"))
	)
	switch flag.Arg(0) {
	case "enc":
		err = encrypt(key, iv, inB, outB)
	case "dec":
		err = decrypt(key, iv, inB, outB)
	case "cmp":
		err = compress(in, out)
	case "dmp":
		err = decompress(in, out)
	default:
		log("no command given")
	}
	check(err)

	if enc {
		io.Copy(out, bytes.NewReader(outB))
	}
}

func decrypt(key, iv, in, out []byte) (err error) {
		block, err := aes.NewCipher(key)
		stream := cipher.NewCBCDecrypter(block, iv)

		stream.CryptBlocks(out, in)

		return
}

func encrypt(key, iv, in, out []byte) (err error) {
		block, err := aes.NewCipher(key)
		stream := cipher.NewCBCEncrypter(block, iv)
		stream.CryptBlocks(out, in)

		return
}

func decompress(in io.Reader, out io.Writer) (err error) {
	dcmp, err := zlib.NewReader(in)
	if err != nil {
		return err
	}
	defer dcmp.Close()


	_, err = io.Copy(out, dcmp)
	if err != nil {
		return err
	}

	return
}

func compress(in io.Reader, out io.Writer) (err error) {
	cmp := zlib.NewWriter(out)
	defer cmp.Close()

	_, err = io.Copy(cmp, in)
	if err != nil {
		return err
	}

	return
}

func log(s string, v ...interface{}) {
	fmt.Fprintf(os.Stderr, s, v...)
}

// taken from andreburgaud/crypt2go
func pad(bs int, buf []byte) []byte {
	bufLen := len(buf)
	padLen := bs - (bufLen % bs)
	padText := bytes.Repeat([]byte{byte(padLen)}, padLen)
	return append(buf, padText...)
}

func mustDecodeHexString(s string) []byte {
	d, e := hex.DecodeString(s)
	if e != nil {
		panic(e)
	}

	return d
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}
