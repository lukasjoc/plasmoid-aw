import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.2
import QtQuick.Window 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kquickcontrols 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.quickcharts 1.0 as Charts

import "main.js" as Main

Item {
    id: widget

    signal clicked();

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.compactRepresentation: Kirigami.Icon {
        id: compact
        source: "ktimetracker"
        active: mouseArea.containsMouse

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                plasmoid.expanded = !plasmoid.expanded
                widget.clicked();
            }
        }
    }
    Plasmoid.fullRepresentation: ColumnLayout {
        id: col

        Component.onCompleted: Main.getLatestHourlyEvents(heading, label, barChart, barModel);
        Connections {
            target: widget
            function onClicked() {
                if(!plasmoid.expanded) {
                    barModel.clear();
                    return;
                }
                Main.getLatestHourlyEvents(heading, label, barChart, barModel);
            }
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

