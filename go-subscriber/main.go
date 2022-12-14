package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

type JSONObj struct {
	PubsubName string `json:"pubsubName"`
	Topic      string `json:"topic"`
	Route      string `json:"route"`
}

type Value struct {
	Kind string
	Name string
	Status string
}

type Data struct {
	Key string
	Value Value

}

type Result struct {
	Data Data
}

func getOrder(w http.ResponseWriter, r *http.Request) {
	jsonData := []JSONObj{
		{
			PubsubName: "planetpubsub",
			Topic:      "planets",
			Route:      "planets",
		},
	}
	jsonBytes, err := json.Marshal(jsonData)
	if err != nil {
		log.Fatal("Error in reading the result obj")
	}
	_, err = w.Write(jsonBytes)
	if err != nil {
		log.Fatal("Error in writing the result obj")
	}
}

func postOrder(w http.ResponseWriter, r *http.Request) {
	data, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Fatal(err)
	}
	var result Result
	err = json.Unmarshal([]byte(data), &result)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Subscriber received: ", result.Data)
	obj, err := json.Marshal(data)
	if err != nil {
		log.Fatal("Error in reading the result obj")
	}
	_, err = w.Write(obj)
	if err != nil {
		log.Fatal("Error in writing the result obj")
	}
}

func main() {
	appPort := "8002"

	r := mux.NewRouter()

	r.HandleFunc("/dapr/subscribe", getOrder).Methods("GET")

	r.HandleFunc("/planets", postOrder).Methods("POST")

	if err := http.ListenAndServe(":"+appPort, r); err != nil {
		log.Panic(err)
	}
}
