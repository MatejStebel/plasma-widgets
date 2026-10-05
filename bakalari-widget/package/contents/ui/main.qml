import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "../code/timetableParser.js" as TimetableParser


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

    property string sessionPassword: ""
    property string accessToken: ""
    property string apiStatus: ""
    property bool apiBusy: false
    function normalizedServerUrl() {
        var url = plasmoid.configuration.serverUrl.trim()

        while (url.endsWith("/")) {
            url = url.slice(0, -1)
        }

        return url
    }


    function loginToBakalari() {
        var server = normalizedServerUrl()
        var username = plasmoid.configuration.username.trim()

        if (server === "") {
            apiStatus = "Server URL is missing"
            return
        }

        if (username === "") {
            apiStatus = "Username is missing"
            return
        }

        if (sessionPassword === "") {
            apiStatus = "Password is missing"
            return
        }

        apiBusy = true
        apiStatus = "Logging in..."

        var request = new XMLHttpRequest()

        request.open(
            "POST",
            server + "/api/login"
        )

        request.setRequestHeader(
            "Content-Type",
            "application/x-www-form-urlencoded"
        )

        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) {
                return
            }

            apiBusy = false

            if (request.status !== 200) {
                apiStatus =
                    "Login failed (HTTP "
                    + request.status
                    + ")"

                console.error(
                    "Bakaláři login failed:",
                    request.responseText
                )

                return
            }

            try {
                var response = JSON.parse(
                    request.responseText
                )

                if (!response.access_token) {
                    apiStatus = "Login response has no access token"
                    return
                }

                accessToken =
                    response.access_token

                apiStatus =
                    "Logged in"

                fetchTimetable()

            } catch (error) {
                apiStatus =
                    "Invalid login response"

                console.error(
                    "Could not parse login response:",
                    error
                )
            }
        }

        var body =
            "client_id=ANDR"
            + "&grant_type=password"
            + "&username="
            + encodeURIComponent(username)
            + "&password="
            + encodeURIComponent(sessionPassword)

        request.send(body)
    }
    function todayForApi() {
        var date = new Date()

        var year = date.getFullYear()

        var month =
            String(date.getMonth() + 1)
            .padStart(2, "0")

        var day =
            String(date.getDate())
            .padStart(2, "0")

        return year + "-" + month + "-" + day
    }


    function fetchTimetable() {
        if (root.accessToken === "") {
            root.apiStatus = "Not logged in"
            return
        }

        root.apiBusy = true
        root.apiStatus = "Loading timetable..."

        var request = new XMLHttpRequest()

        var url =
            root.normalizedServerUrl()
            + "/api/3/timetable/actual?date="
            + root.todayForApi()

        request.open(
            "GET",
            url
        )

        request.setRequestHeader(
            "Authorization",
            "Bearer " + root.accessToken
        )

        request.onreadystatechange = function() {
            if (
                request.readyState
                !== XMLHttpRequest.DONE
            ) {
                return
            }

            root.apiBusy = false

            if (request.status !== 200) {
                root.apiStatus =
                    "Timetable failed (HTTP "
                    + request.status
                    + ")"

                console.error(
                    "Timetable request failed:",
                    request.responseText
                )

                return
            }

            try {
                var data = JSON.parse(
                    request.responseText
                )

                var parsed =
                    TimetableParser.parseTimetable(
                        data
                    )

                root.cycle =
                    parsed.cycle

                root.lessonTimes =
                    parsed.hours

                root.days =
                    parsed.days

                root.apiStatus =
                    "Timetable updated"

                console.log(
                    "Live timetable:",
                    parsed.days.length,
                    "days,",
                    parsed.hours.length,
                    "hours"
                )

            } catch (error) {
                root.apiStatus =
                    "Invalid timetable response"

                console.error(
                    "Could not parse timetable:",
                    error
                )
            }
        }

        request.send()
    }

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

        Layout.minimumWidth: 360

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
                    timetableColumn.implicitHeight
                )


                ColumnLayout {
                    id: timetableColumn
                    anchors.fill: parent

                    spacing:
                        representation.cellSpacing


                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        text:
                            plasmoid.configuration.username !== ""
                            ? "Weekly schedule — "
                                + plasmoid.configuration.username
                            : "Weekly schedule — not configured"

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        font.pixelSize: 20
                        font.bold: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 320

                        spacing: 8

                        TextField {
                            id: passwordField

                            Layout.fillWidth: true
                            Layout.minimumWidth: 220

                            placeholderText:
                                i18n("Bakaláři password")

                            echoMode:
                                TextInput.Password

                            enabled:
                                !root.apiBusy

                            onTextChanged:
                                root.sessionPassword = text

                            onAccepted:
                                root.loginToBakalari()
                        }

                        Button {
                            text:
                                root.apiBusy
                                ? i18n("Loading...")
                                : i18n("Login")

                            enabled:
                                !root.apiBusy

                            onClicked:
                                root.loginToBakalari()
                        }
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true

                        visible:
                            root.apiStatus !== ""

                        text:
                            root.apiStatus

                        horizontalAlignment:
                            Text.AlignHCenter

                        opacity: 0.8
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
