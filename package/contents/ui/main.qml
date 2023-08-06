import QtQuick 2.11
import QtQuick.Controls 2.11
import QtQuick.Layouts 1.2
import QtQuick.Window 2.11
import org.kde.kquickcontrols 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.quickcharts 1.0 as Charts
import "main.js" as Main

Item {
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.compactRepresentation: ColumnLayout {
        Component.onCompleted: Main.getLatestHourlyEvents(heading, label, barChart, barModel);

        Timer {
            interval: 1000*5;
            running: true;
            repeat: true;
            onTriggered: Main.getLatestHourlyEvents(heading, label, barChart, barModel);
        }

        spacing: 2;
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
            barWidth: 10
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
