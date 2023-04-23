import QtQuick
import QtQuick.Controls

Slider {
    id: control
    value: 0.5
    orientation: Qt.Vertical

    background: Rectangle {
        x: control.leftPadding + control.availableWidth / 2 - width / 2
        y: control.topPadding
        implicitWidth: 6
        implicitHeight: 200
        width: implicitWidth
        height: control.availableHeight
        radius: 2
        color: "#bdbebf"

        Rectangle {
            width: parent.width
            height: parent.height - control.visualPosition * parent.height
            color: "#432464"
            radius: 2
            y: parent.height - height
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.availableWidth / 2 - width / 2
        y: control.topPadding + control.visualPosition * (control.availableHeight - height)
        width: 20
        height: 20
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: control.pressed ? "#f0f0f0" : "#f6f6f6"
        border.color: "#432464"
    }
}
