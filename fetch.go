package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"time"
)

// Example Event
//	{
//			"id": null,
//			"timestamp": "2023-07-30T09:43:41.133000+00:00",
//			"duration": 19947.299,
//			"data": {
//				"app": "Gnome-terminal"
//			}
//		}

type EventData struct {
	App string `json:"app"`
}

type Event struct {
	ID        int       `json:"id"`
	Timestamp time.Time `json:"timestamp"`
	Duration  float64   `json:"duration"`
	Data      EventData `json:"data"`
}

type Events struct {
	Events []Event `json:"events"`
	hours  []int
}

func (e *Events) ByHours() map[int][]Event {
	byHours := make(map[int][]Event)
	for _, event := range e.Events {
		hour := event.Timestamp.Local().Hour()
		if _, ok := byHours[hour]; !ok {
			e.hours = append(e.hours, hour)
			byHours[hour] = []Event{}
		}
		byHours[hour] = append(byHours[hour], event)
	}
	return byHours
}

func main() {
	content, err := ioutil.ReadFile("data.json")
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v", err)
	}

	var events Events
	err = json.Unmarshal(content, &events)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v", err)
	}

	byHours := events.ByHours()
	for _, hour := range events.hours {
		fmt.Printf("%v %v\n\n", hour, byHours[hour])
	}
}
