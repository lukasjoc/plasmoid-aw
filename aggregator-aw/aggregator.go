package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

const (
    HoursPerDay = 24
    MinutesPerHour = 60
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
		q.Query = append(q.Query, queryArg)
	}
}

func (q *QueryBuilder) Build() ([]byte, error) {
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	tomorrow := today.Add(HoursPerDay * time.Hour)
	period := fmt.Sprintf(
		"%s/%s",
		today.Format("2006-01-02T15:04:05-07:00"),
		tomorrow.Format("2006-01-02T15:04:05-07:00"),
	)
	q.TimePeriods = append(q.TimePeriods, period)
	q.Add(";")
	return json.Marshal(q)
}

func getCurrentEvents() ([]Events, error) {
	baseURL := "http://localhost:5600/api/0/query/"

	var q QueryBuilder
	q.Add(
        `events = query_bucket(find_bucket("aw-watcher-window_"));`,
		`summed = sum_durations(events);`,
		`RETURN = {"events": events, "duration": summed};`,
	)

	query, err := q.Build()
	if err != nil {
		return nil, err
	}

	body := bytes.NewBuffer(query)
	res, err := http.Post(baseURL, "application/json", body)
	if err != nil {
		return nil, err
	}

	defer res.Body.Close()
	content, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}
	var events []Events
	err = json.Unmarshal(content, &events)
	if err != nil {
		return nil, err
	}
	return events, err
}

type HourlyEvent struct {
	Hourly      []float64 `json:"hourly"`
	Accumulated float64   `json:"accumulated"`
}

func FromEvents(events []Events) HourlyEvent {
	var he HourlyEvent
	he.Hourly = make([]float64, HoursPerDay)
	e := events[0]
	byHours := e.ByHours()
	for _, hour := range e.hours {
		summed := sumDurations(byHours[hour])
		he.Hourly[hour] = (summed / MinutesPerHour)
	}
	he.Accumulated = (e.Duration /  MinutesPerHour)
	return he
}

func main() {
	e := echo.New()
    e.Use(middleware.Logger())
	e.Use(middleware.GzipWithConfig(middleware.GzipConfig{Level: 5}))
	e.Use(middleware.CSRF())
	e.GET("/hourly", func(c echo.Context) error {
		events, err := getCurrentEvents()
		if err != nil {
			return err
		}
		bl, err := json.Marshal(FromEvents(events))
        if err != nil {
            return err
        }
		return c.JSONBlob(http.StatusOK, bl)
	})
	e.Logger.Fatal(e.Start(":3343"))
}

