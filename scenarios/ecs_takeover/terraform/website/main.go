package main

import (
	// Import the gorilla/mux library we just installed

	"bytes"
	"fmt"
	"html/template"
	"net/http"
	"os/exec"

	"github.com/gorilla/mux"
)

type Demo1Page struct {
	Request  string
	Response string
}

func main() {
	// Declare a new router
	r := mux.NewRouter()

	// This is where the router is useful, it allows us to declare methods that
	// this path will be valid for
	r.HandleFunc("/", demo1).Methods("GET")

	// We can then pass our router (after declaring all our routes) to this method
	// (where previously, we were leaving the second argument as nil)

	fmt.Println("Starting website on :80")

	err := http.ListenAndServe(":80", r)

	if err != nil {
		fmt.Println(err)
	}
}

func demo1(w http.ResponseWriter, r *http.Request) {

	var tpl = template.Must(template.ParseFiles("assets/index.html"))
	url := r.URL.Query().Get("url")

	data := Demo1Page{}

	if len(url) > 0 {
		data = handelGetRequest(url)
	}

	tpl.Execute(w, data)

}

func handelGetRequest(cmd string) Demo1Page {
	data := Demo1Page{Request: cmd, Response: ""}

	exec := exec.Command("/bin/sh", "-c", "curl "+cmd)

	var out bytes.Buffer
	exec.Stdout = &out

	err := exec.Run()

	if err != nil {
		data.Response = "Failed to clone website."
		return data
	}

	data.Response = out.String()

	return data
}
