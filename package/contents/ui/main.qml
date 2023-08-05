import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import QtQuick 2.11
import QtQuick.Controls 2.11
import QtQuick.Layouts 1.0
import org.kde.quickcharts 1.0 as Charts
import QtQuick.Window 2.11
import org.kde.plasma.extras 2.0 as PlasmaExtras
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.kquickcontrols 2.0
import org.kde.quickcharts 1.0 as Charts

ColumnLayout {
    spacing: 2

    PlasmaExtras.Heading {
        type: PlasmaExtras.Heading.Type.Primary
        Layout.alignment: Qt.AlignRight
        // Component.onCompleted: {
        //     const r = new XMLHttpRequest()
        //     // console.log("HEADING ANYONE?")
        // }
        // TODO: get from api dynamically and format
        text: "5h 28m"
    }

    Charts.BarChart {
        id: barChart
        barWidth: 5
        spacing: 1
        radius: 2

        width: 120
        height: 120
        backgroundColor: Qt.rgba(0.0, 0.0, 0.0, 0.1)

        valueSources: [
            Charts.ModelSource {
                model: barModel
                roleName: "usageMinutes"
            }
        ]

        xRange {
            // TODO: should be dynamic from usage data
            from: 0; to: 14
            automatic: false
        }

        yRange {
            from: 0; to: 60
            automatic: false
        }

        colorSource: Charts.ArraySource { array: ["#3b83f7"] }

        ListModel {
            id: barModel
            Component.onCompleted: {
                // TODO: cool XHRrequest works :0
                console.log("HALLO DU SACK: ", typeof XMLHttpRequest)
                const pool = [10, 50, 30, 25];
                for(var i = 0; i < 12; i++) {
                    const faked = pool[Math.floor(Math.random() * pool.length)]
                    append({usageMinutes: faked });
                }
            }
        }

        Charts.AxisLabels {
            id: yAxisLabels
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            direction: Charts.AxisLabels.VerticalBottomTop
            delegate: Label {
                text: Charts.AxisLabels.label
            }
            source: Charts.ArraySource { array: [0, 30, 60] }
        }

        Charts.AxisLabels {
            id: xAxisLabels
            anchors {
                left: parent.left
                right: yAxisLabels.left
                bottom: parent.bottom
            }
            delegate: Label {
                text: Charts.AxisLabels.label
            }
            // TODO: generate dynamically based on data
            source: Charts.ArraySource { array: [0, 9, 14] }
        }

    }

}

