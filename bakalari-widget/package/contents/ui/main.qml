import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

import "../data/timetable.js" as TimetableData

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property string cycle:
	TimetableData.timetable.cycle || ""

    property var lessonTimes:
    	TimetableData.timetable.hours || []

    property var days:
    	TimetableData.timetable.days || []

    property string loadError: ""

    function lessonForHour(day, hourId) {
        if (!day || !day.lessons) {
            return null
        }

        for (
            var i = 0;
            i < day.lessons.length;
            i++
        ) {
            var lesson = day.lessons[i]

            if (
                String(lesson.hourId)
                === String(hourId)
            ) {
                return lesson
            }
        }

        return null
    }


    function dayName(dayNumber) {
        switch (Number(dayNumber)) {
        case 1:
            return "Monday"

        case 2:
            return "Tuesday"

        case 3:
            return "Wednesday"

        case 4:
            return "Thursday"

        case 5:
            return "Friday"

        case 6:
            return "Saturday"

        case 7:
            return "Sunday"

        default:
            return ""
        }
    }


    fullRepresentation: Item {
        id: representation

        implicitWidth: 900
        implicitHeight: 500

        property int dayWidth: 90
        property int lessonWidth: 110
        property int headerHeight: 55
        property int lessonHeight: 90
        property int cellSpacing: 5


        Flickable {
            id: timetableScroll

            anchors.fill: parent

            contentWidth: timetable.width
            contentHeight: timetable.height

            clip: true

            flickableDirection:
                Flickable.HorizontalAndVerticalFlick

            boundsBehavior:
                Flickable.StopAtBounds


            ScrollBar.horizontal:
                PlasmaComponents.ScrollBar {
                    policy: ScrollBar.AsNeeded
                }


            ScrollBar.vertical:
                PlasmaComponents.ScrollBar {
                    policy: ScrollBar.AsNeeded
                }


            Item {
                id: timetable

                width: Math.max(
                    timetableScroll.width,

                    representation.dayWidth
                    + root.lessonTimes.length
                    * representation.lessonWidth
                    + root.lessonTimes.length
                    * representation.cellSpacing
                )

                height: Math.max(
                    timetableScroll.height,

                    40
                    + representation.headerHeight
                    + root.days.length
                    * representation.lessonHeight
                    + root.days.length
                    * representation.cellSpacing
                )


                ColumnLayout {
                    anchors.fill: parent

                    spacing:
                        representation.cellSpacing


                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        text:
                            root.loadError !== ""
                            ? root.loadError
                            : "Weekly schedule"

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        font.pixelSize: 20
                        font.bold: true
                    }


                    // -------------------------
                    // Hour header
                    // -------------------------

                    RowLayout {
                        Layout.fillWidth: true

                        Layout.preferredHeight:
                            representation.headerHeight

                        spacing:
                            representation.cellSpacing


                        // Top-left corner:
                        // current Bakaláři cycle
                        PlasmaComponents.Label {
                            Layout.minimumWidth:
                                representation.dayWidth

                            Layout.preferredWidth:
                                representation.dayWidth

                            Layout.fillHeight: true

                            text: root.cycle

                            horizontalAlignment:
                                Text.AlignHCenter

                            verticalAlignment:
                                Text.AlignVCenter

                            font.bold: true
                            font.pixelSize: 18
                        }


                        Repeater {
                            model: root.lessonTimes

                            delegate: ColumnLayout {
                                required property var modelData

                                Layout.fillWidth: true

                                Layout.minimumWidth:
                                    representation.lessonWidth

                                Layout.preferredWidth:
                                    representation.lessonWidth

                                spacing: 0


                                PlasmaComponents.Label {
                                    Layout.fillWidth: true

                                    // Uses Hours[].Caption,
                                    // not Hours[].Id.
                                    text: modelData.number

                                    horizontalAlignment:
                                        Text.AlignHCenter

                                    font.bold: true
                                    font.pixelSize: 16
                                }


                                PlasmaComponents.Label {
                                    Layout.fillWidth: true

                                    text:
                                        modelData.start
                                        + "–"
                                        + modelData.end

                                    horizontalAlignment:
                                        Text.AlignHCenter

                                    font.pixelSize: 11
                                    opacity: 0.7
                                }
                            }
                        }
                    }


                    // -------------------------
                    // Days
                    // -------------------------

                    Repeater {
                        model: root.days

                        delegate: RowLayout {
                            id: dayRow

                            required property var modelData

                            property var dayData:
                                modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Layout.minimumHeight:
                                representation.lessonHeight

                            Layout.preferredHeight:
                                representation.lessonHeight

                            spacing:
                                representation.cellSpacing


                            PlasmaComponents.Label {
                                Layout.minimumWidth:
                                    representation.dayWidth

                                Layout.preferredWidth:
                                    representation.dayWidth

                                Layout.fillHeight: true

                                text:
                                    root.dayName(
                                        dayRow.dayData.dayOfWeek
                                    )

                                horizontalAlignment:
                                    Text.AlignHCenter

                                verticalAlignment:
                                    Text.AlignVCenter

                                font.bold: true
                            }

                            Rectangle {
                                visible:
                                dayRow.dayData.allDayEvent === true

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Layout.minimumHeight:
                                representation.lessonHeight

                                radius: 6

                                color: Qt.rgba(
                                    0.5,
                                    0.5,
                                    0.5,
                                    0.15
                                )

                                border.width: 1

                                border.color: Qt.rgba(
                                    0.5,
                                    0.5,
                                    0.5,
                                    0.3
                                )

                                PlasmaComponents.Label {
                                    anchors.fill: parent
                                    anchors.margins: 8

                                    text:
                                    dayRow.dayData.eventText || ""

                                    horizontalAlignment:
                                    Text.AlignHCenter

                                    verticalAlignment:
                                    Text.AlignVCenter

                                    wrapMode:
                                    Text.WordWrap

                                    font.bold: true
                                }
                            }

                            // One cell for every displayed
                            // school hour.
                            Repeater {
                                model:
                                dayRow.dayData.allDayEvent
                                ? []
                                : root.lessonTimes

                                delegate: Rectangle {
                                    required property var modelData

                                    property var lesson:
                                        root.lessonForHour(
                                            dayRow.dayData,
                                            modelData.id
                                        )

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Layout.minimumWidth:
                                        representation.lessonWidth

                                    Layout.preferredWidth:
                                        representation.lessonWidth

                                    Layout.minimumHeight:
                                        representation.lessonHeight

                                    radius: 6

                                    color: {
                                        if (!lesson) {
                                            return "transparent"
                                        }

                                        if (lesson.status === "cancelled") {
                                            return Qt.rgba(
                                                0.2,
                                                0.8,
                                                0.2,
                                                0.25
                                            )
                                        }

                                        if (lesson.status === "changed") {
                                            return Qt.rgba(
                                                1.0,
                                                0.65,
                                                0.0,
                                                0.25
                                            )
                                        }

                                        return Qt.rgba(
                                            0.5,
                                            0.5,
                                            0.5,
                                            0.15
                                        )
                                    }

                                    border.width:
                                        lesson ? 1 : 0

                                    border.color:
                                        Qt.rgba(
                                            0.5,
                                            0.5,
                                            0.5,
                                            0.3
                                        )


                                    ColumnLayout {
                                        anchors.centerIn:
                                            parent

                                        width:
                                            parent.width - 10

                                        spacing: 2


                                        PlasmaComponents.Label {
                                            Layout.fillWidth: true

                                            visible:
                                                lesson !== null

                                            text:
                                                lesson
                                                ? lesson.subject
                                                : ""

                                            horizontalAlignment:
                                                Text.AlignHCenter

                                            font.bold: true
                                            font.pixelSize: 15
                                        }


                                        PlasmaComponents.Label {
                                            Layout.fillWidth: true

                                            visible:
                                                lesson !== null

                                            text:
                                                lesson
                                                ? lesson.teacher
                                                : ""

                                            horizontalAlignment:
                                                Text.AlignHCenter

                                            font.pixelSize: 12
                                        }


                                        PlasmaComponents.Label {
                                            Layout.fillWidth: true

                                            visible:
                                                lesson !== null

                                            text:
                                                lesson
                                                ? lesson.room
                                                : ""

                                            horizontalAlignment:
                                                Text.AlignHCenter

                                            font.pixelSize: 11
                                            opacity: 0.7
                                        }
                                        PlasmaComponents.Label {
                                            Layout.fillWidth: true

                                            visible:
                                                lesson !== null
                                                && lesson.change !== null
                                                && lesson.change.description !== undefined
                                                && lesson.change.description !== ""

                                            text:
                                                visible
                                                ? lesson.change.description
                                                : ""

                                            horizontalAlignment:
                                                Text.AlignHCenter

                                            wrapMode:
                                                Text.WordWrap

                                            maximumLineCount: 2
                                            elide: Text.ElideRight

                                            font.pixelSize: 10
                                            opacity: 0.8
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
