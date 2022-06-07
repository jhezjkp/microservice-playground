package main

import (
	"encoding/binary"
	"fmt"
	"strconv"
	"time"

	"github.com/hashicorp/consul/api"
	"github.com/sanbornm/go-selfupdate/selfupdate"
)

func main() {
	version := "3"
	var updater = &selfupdate.Updater{
		CurrentVersion: version,
		ApiURL:         "http://123.207.56.106/",
		BinURL:         "http://123.207.56.106/",
		DiffURL:        "http://123.207.56.106/",
		Dir:            "update/",
		CmdName:        "test", // app name
	}

	if updater != nil {
		go updater.BackgroundRun()
	}

	fmt.Printf("version: %v\n", version)

	// Get a new client
	client, err := api.NewClient(api.DefaultConfig())
	if err != nil {
		panic(err)
	}

	// Get a handle to the KV API
	kv := client.KV()

	lastEventKey := "LAST_EVENT_KEY"
	// Lookup the pair
	pair, _, err := kv.Get(lastEventKey, nil)
	if err != nil {
		panic(err)
	}
	lastIndex := uint64(1)
	if pair != nil {
		lastIndex, _ = strconv.ParseUint(string(pair.Value), 10, 64)
		//fmt.Println(strconv.ParseUint(string(pair.Value), 10, 64))

		/*fmt.Printf("KV: %v %s\n", pair.Key, pair.Value)*/
		//fmt.Printf("KV: %v %d\n", pair.Key, lastIndex)
		/*f*/
		fmt.Println(lastIndex)
	}

	event := client.Event()
	evt, qm, err := event.List("", &api.QueryOptions{WaitTime: 10 * time.Second, WaitIndex: lastIndex})
	fmt.Println(evt)
	fmt.Println(qm)
	lastIndex = qm.LastIndex

	bytes := make([]byte, 8)
	binary.LittleEndian.PutUint64(bytes, lastIndex)
	p := &api.KVPair{Key: lastEventKey, Value: []byte(strconv.FormatUint(lastIndex, 10))}
	_, err = kv.Put(p, nil)
}
