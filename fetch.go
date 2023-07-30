package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"sort"
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
	App   string `json:"app"`
	Title string `json:"title"`
}

type Event struct {
	ID        int       `json:"id"`
	Timestamp time.Time `json:"timestamp"`
	Duration  float64   `json:"duration"`
	Data      EventData `json:"data"`
}

type Events struct {
	Events   []Event `json:"events"`
	Duration float64 `json:"duration"`
	hours    []int
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
	sort.Ints(e.hours)
	return byHours
}

func sumDurations(events []Event) (sum float64) {
	for _, event := range events {
		sum += event.Duration
	}
	return sum
}

func main() {
	content, err := ioutil.ReadFile("data.json")
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
	}

	var events []Events
	err = json.Unmarshal(content, &events)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
	}

	byHours := events[0].ByHours()
	// for _, hour := range events.hours {
	//     for _, event := range byHours[hour] {
	//         fmt.Printf("h:%d e:%v\n", hour, event.Timestamp)
	//     }
	// }
	for _, hour := range events[0].hours {
		summed := sumDurations(byHours[hour])
		duration := time.Duration(summed) * time.Second
		fmt.Printf("h:%v => d:%s\n", hour, duration.Round(duration))
	}

	total := time.Duration(events[0].Duration) * time.Second
	fmt.Printf("total: d:%s\n", total.Round(total))
}
