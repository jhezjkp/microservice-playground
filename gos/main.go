package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	consulapi "github.com/hashicorp/consul/api"
	"github.com/rs/zerolog"
	logger "github.com/rs/zerolog/log"
)

// 程序版本号
var VERSION string = "alpha"

// 参数项
var showHelp, showVersion, dev bool

// consul服务器接入地址
var consulServerAddr string

func usage() {
	fmt.Println("Usage gos [-version] [-help] <command> [<args>]")
	flag.PrintDefaults()
}

func init() {
	// 获取本机ip
	var localIp string = "localhost"
	/*addrs, err := net.InterfaceAddrs()*/
	//if err != nil {
	//os.Stderr.WriteString("Error:" + err.Error() + "\n")
	//os.Exit(1)
	//}
	//for _, a := range addrs {
	//if ipnet, ok := a.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
	//if ipnet.IP.To4() != nil {
	//fmt.Println(ipnet.Network())
	//fmt.Println(ipnet.IP.To4())
	//localIp = ipnet.IP.To4().String()
	//}
	//}
	/*}*/

	flag.BoolVar(&showHelp, "help", false, "show usage")
	flag.BoolVar(&showVersion, "version", false, "show version")
	flag.BoolVar(&dev, "dev", false, "enable dev mode")
	flag.StringVar(&consulServerAddr, "server", localIp+":8500", "consul server address")

	flag.Usage = usage
	flag.Parse()

	// 设置日志级别
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
	if dev {
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
		logger.Logger = logger.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	} else {
		f, _ := os.OpenFile("run.log", os.O_RDWR|os.O_APPEND, 0755)
		logger.Logger = logger.Output(zerolog.ConsoleWriter{Out: f, NoColor: true})
	}

	logger.Debug().Str("ip", localIp).Msg("本机IP")

	// 加入consul集群
	config := consulapi.DefaultConfig()
	config.Address = consulServerAddr
	client, _ := consulapi.NewClient(config)
	agent := client.Agent()
	//err = agent.Join("192.168.33.101", false)
	/*agent.Join(localIp, false)*/
	//if err != nil {
	//fmt.Println(err)
	/*}*/
	members, _ := agent.Members(false)
	logger.Debug().Int("members", len(members)).Msg("集群")
	for _, m := range members {
		logger.Debug().Str("name", m.Name).Str("address", m.Addr).Uint16("port", m.Port).Msg("member")
	}

	// other
	//go monitorEvent(client.KV(), client.Event())
}

func deploy() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Enter text: ")
	text, _ := reader.ReadString('\n')
	fmt.Println(strings.Trim(text, "\n"))
	ues := []consulapi.UserEvent{}
	json.Unmarshal([]byte(text), &ues)
	fmt.Println(len(ues))
	fmt.Println(ues[0].ID)
	fmt.Println(ues[0])
}

func monitorEvent(kv *consulapi.KV, event *consulapi.Event) {
	options := new(consulapi.QueryOptions)
	pair, _, err := kv.Get("index", nil)
	if err == nil && pair != nil {
		value, err := strconv.ParseUint(string(pair.Value), 10, 64)
		fmt.Println(err)
		fmt.Println(pair.Key + ":" + string(pair.Value))
		fmt.Println(pair.Key + ":" + string(value))
		fmt.Println(value)
		options.WaitIndex = value
	}
	for {
		ues, qm, err := event.List("deploy", options)
		if err == nil {
			for _, ue := range ues {
				if data, err := json.Marshal(ue); err == nil {
					fmt.Println(string(data))
				}
			}
			fmt.Println(*qm)
			options.WaitIndex = qm.LastIndex
			kv.Put(&consulapi.KVPair{Key: "index", Value: []byte(strconv.FormatUint(qm.LastIndex, 10))}, nil)
		}
		time.Sleep(10 * 1e9)
	}
}

func main() {
	if showHelp || flag.NArg() == 0 {
		usage()
		os.Exit(0)
	} else if showVersion {
		fmt.Println("version: " + VERSION)
		os.Exit(0)
	}

	var cmd string = flag.Arg(0)
	switch cmd {
	case "start":
		fmt.Println("prepare to start")
		break
	case "deploy":
		fmt.Println("prepare to deploy")
		deploy()
		break
	default:
		fmt.Println("unknown command")
		//select {}
	}
}