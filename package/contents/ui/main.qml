import QtQuick 2.11
import QtQuick.Controls 2.11
import QtQuick.Layouts 1.2
import QtQuick.Window 2.11
import org.kde.kquickcontrols 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.quickcharts 1.0 as Charts

Item {
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: ColumnLayout {
        Component.onCompleted: {
            const baseURL = "http://localhost:3343/hourly"
            const req = new XMLHttpRequest();
            req.onreadystatechange = function() {
                if (req.readyState !== XMLHttpRequest.DONE) {
                    return;
                }
                if (req.status === 200) {
                    const data = JSON.parse(req.responseText);

                    const hours = Object.entries(data.hourly)

                    // Preparing all of the data for the barchart
                    for(let hour = 0; hour < hours.length; hour++) {
                        const usage = data.hourly[hour]
                        if(usage === 0.0) {
                            continue
                        }
                        barModel.append({usageMinutes: usage > 60.0 ? 60 : usage});
                    }

                    // Setting the text for the heading
                    const accumulatedHours = Math.floor(data.accumulated / 60);
                    const accumulatedMinutes = Math.round(data.accumulated % 60);
                    const parts = [];
                    if(accumulatedHours > 0) {
                        parts.push(accumulatedHours + 'h')
                    }
                    if(accumulatedMinutes > 0) {
                        parts.push(accumulatedMinutes + 'm')
                    }
                    heading.text = parts.join(" ")

                    // Setting the text for the hour range
                    const range = [];
                    const [start]= hours.find(([h, m]) => m > 0.0);
                    hours.reverse();
                    const [current] = hours.find(([h, m]) => m > 0.0);
                    if(start !== current) {
                        range.push(start, current)
                        label.text = `(${range.join(' - ')})`
                    }else {
                        label.text = ""
                    }
                }
            };
            req.open("GET", baseURL);
            req.send();
        }

        spacing: 2
        RowLayout {
            PlasmaExtras.Heading {
                type: PlasmaExtras.Heading.Type.Primary
                id: heading
                text: "00h 00m"
            }
            Label {
                id: label
                text: "(?? - ??)"
            }
        }

        Charts.BarChart {
            id: barChart
            width: 128
            height: 128
            backgroundColor: Qt.rgba(0.0, 0.0, 0.0, 0.1)
            barWidth: 8
            spacing: 2
            radius: 2

            yRange {
                from: 0
                to: 60
                automatic: false
            }

            colorSource: Charts.ArraySource {
                array: [ "#3a94a8" ]
            }

            valueSources: [
                Charts.ModelSource {
                    model: barModel
                    roleName: "usageMinutes"
                }
            ]

            ListModel {
                id: barModel
            }
        }
    }
}
