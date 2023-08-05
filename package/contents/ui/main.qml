import QtQuick 2.11
import QtQuick.Controls 2.11
import QtQuick.Layouts 1.2
import QtQuick.Window 2.11
import org.kde.kquickcontrols 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.quickcharts 1.0 as Charts

Item {
    function getHourlyData(cb) {
        const req = new XMLHttpRequest();
        req.onreadystatechange = () => {
            if (req.readyState !== XMLHttpRequest.DONE) {
                return
            }
            cb(JSON.parse(req.response))
        }
        req.open("GET", "http://localhost:3343/hourly");
        req.send();
    }

    id: widget

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.compactRepresentation: ColumnLayout {
        spacing: 2

        RowLayout {
            PlasmaExtras.Heading {
                type: PlasmaExtras.Heading.Type.Primary
                id: hoursAccumulated
                Component.onCompleted: {
                    getHourlyData((data) => {
                        const accumulated = data.accumulated;
                        const hours = Math.floor(accumulated / 60);
                        const minutes = Math.round(accumulated % 60);
                        const parts = [];
                        if(hours > 0) {
                            parts.push(hours + 'h')
                        }
                        if(minutes > 0) {
                            parts.push(minutes + 'm')
                        }
                        hoursAccumulated.text = parts.join(" ")
                    });
                }
            }
            Label {
                id: hoursAccumulated1
                Component.onCompleted: {
                    getHourlyData((data) => {
                        const range = [];
                        const hours = Object.entries(data.hourly);
                        const [start]= hours.find(([h, m]) => m > 0);
                        hours.reverse();
                        const [current] = hours.find(([h, m]) => m > 0);
                        range.push(start, current)
                        hoursAccumulated1.text = `(${range.join(' - ')})`
                    });
                }
            }
        }

        Charts.BarChart {
            id: barChart
            barWidth: 8
            spacing: 2
            radius: 2

            width: 128
            height: 128
            backgroundColor: Qt.rgba(0.0, 0.0, 0.0, 0.1)

            valueSources: [
                Charts.ModelSource {
                    model: barModel
                    roleName: "usageMinutes"
                }
            ]

            yRange {
                from: 0;
                to: 60;
                automatic: false
            }

            colorSource: Charts.ArraySource { array: [ "#3a94a8" ] }

            ListModel {
                id: barModel
                Component.onCompleted: {
                    const hourlyEvents = [];
                    getHourlyData((data) => {
                        for(let hour = 0; hour < Object.keys(data.hourly).length; hour++) {
                            let usage = data.hourly[hour]
                            if(usage === 0.0) {
                                continue
                            }
                            append({usageMinutes: usage > 60.0 ? 60 : usage});
                        }
                    });
                }
            }
        }
    }
}
