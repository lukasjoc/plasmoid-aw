package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"os"
	"sort"
	"time"
)

func fatal(err any) {
	fmt.Fprintf(os.Stderr, "fatal: %v", err)
	os.Exit(1)
}

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

type QueryBuilder struct {
	Query       []string `json:"query"`
	TimePeriods []string `json:"timeperiods"`
}

func (q *QueryBuilder) Add(queryArgs ...string) {
	for _, queryArg := range queryArgs {
		fmt.Printf("Adding query: %v\n", queryArg)
		q.Query = append(q.Query, queryArg)
	}
}

func (q *QueryBuilder) Build() ([]byte, error) {
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	tomorrow := today.Add(24 * time.Hour)
	period := fmt.Sprintf(
		"%s/%s",
		today.Format("2006-01-02T15:04:05-07:00"),
		tomorrow.Format("2006-01-02T15:04:05-07:00"),
	)
	fmt.Printf("Adding timeperiod: %v\n", period)
	q.TimePeriods = append(q.TimePeriods, period)
	q.Add(";")
	return json.Marshal(q)
}

func main() {
	q := QueryBuilder{}
	q.Add(
		`events = query_bucket("aw-watcher-window_omega");`,
		`summed = sum_durations(events);`,
		`RETURN = {"events": events, "duration": summed};`,
	)

	body, err := q.Build()
	if err != nil {
		fatal(err)
	}

	res, err := http.Post(
		"http://localhost:5600/api/0/query/", "application/json", bytes.NewBuffer(body))
	if err != nil {
		fatal(err)
	}

	defer res.Body.Close()
	// b, err := httputil.DumpResponse(res, true)
	// if err != nil {
	//     fatal(err)
	// }
	// fmt.Printf(string(b))

	content, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
	}

	os.WriteFile("resp.json", content, fs.ModePerm)

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
