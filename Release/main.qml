import QtQuick
import QtQuick.Window
import QtQuick.Controls 6.3
import QtQuick.Layouts 6.3
import "qml"

Window {
    //главное окно
    id: mainWindow
    width: 600
    height: 800
    visible: true
    color: "#a283c2"
    maximumHeight: 2000
    maximumWidth: 2000
    minimumHeight: 310
    minimumWidth: 210
    flags: Qt.Window | Qt.FramelessWindowHint
    title: qsTr("Face Blur")
    property real aspectRatio: width / height

    //область для обрабатывания событий resize окна, так как мы убрали эту возможность указав флаг Qt.FramelessWindowHint
    MouseArea {
        id: windowResize
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        property int edges: 0;
        property int edgeOffest: 7;

        function setEdges(x, y) {
            edges = 0;
            if(x < edgeOffest) edges |= Qt.LeftEdge;
            if(x > (width - edgeOffest))  edges |= Qt.RightEdge;
            if(y < edgeOffest) edges |= Qt.TopEdge;
            if(y > (height - edgeOffest)) edges |= Qt.BottomEdge;
        }

        cursorShape: {
            return !containsMouse ? Qt.ArrowCursor:
                                    edges == 3 || edges == 12 ? Qt.SizeFDiagCursor :
                                                                edges == 5 || edges == 10 ? Qt.SizeBDiagCursor :
                                                                                            edges & 9 ? Qt.SizeVerCursor :
                                                                                                        edges & 6 ? Qt.SizeHorCursor : Qt.ArrowCursor;
        }

        onPositionChanged: setEdges(mouseX, mouseY);
        onPressed: {
            setEdges(mouseX, mouseY);
            if(edges && containsMouse) {
                startSystemResize(edges);
            }
        }
        onReleased: {
            if (image.source != ""){
                mainWindow.width += Math.min(0, image.paintedWidth - image.width);
                mainWindow.height += Math.min(0, image.paintedHeight - image.height);
            }
        }

    }
    //слайдер для изменения размытия
    CustomSlider{
        default_value: 33
        default_value_color: "#a283c2"

        id: blurSlider
        from: 1
        to: 99
        stepSize: 2
        value: 33
        anchors.left: imgBorder.right
        anchors.top: imgBorder.top
        anchors.bottom: imgBorder.bottom
        anchors.bottomMargin: 0
        anchors.leftMargin: 25
        anchors.topMargin: 0

        onMoved: {
            if (blurSlider.value >= 31 && blurSlider.value <= 35){
                blurSlider.value = 33
            }
            backend.blur_slider_moved(blurSlider.value)
        }
    }
    //слайдер для изменения области размытия
    CustomSlider{
        default_value: 0
        default_value_color: "#a283c2"

        id: areaSlider
        anchors.left: blurSlider.right
        anchors.right: parent.right
        anchors.top: imgBorder.top
        anchors.bottom: imgBorder.bottom
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 20
        anchors.rightMargin: 13
        from: -40
        to: 50
        stepSize: 2
        value: 0


        onMoved: {
            if (areaSlider.value >= -2 && areaSlider.value <= 2){
                areaSlider.value = 0
            }
            backend.area_slider_moved(areaSlider.value)
        }

    }
    //топ бар приложения
    Rectangle {
        id: topBar
        height: 40
        color: "#432464"
        border.color: "#432464"
        border.width: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0

        Text {
            color: "#ffffff"
            text: "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\np, li { white-space: pre-wrap; }\nhr { height: 1px; border-width: 0; }\nli.unchecked::marker { content: \"\\2610\"; }\nli.checked::marker { content: \"\\2612\"; }\n</style></head><body style=\" font-family:'Segoe UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-family:'Segoe UI Black'; font-size:14pt;\">FACE BLUR</span></p></body></html>"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: minimizeBtn.left
            font.pixelSize: 30
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.RichText
            font.styleName: "Полужирный"
            anchors.rightMargin: 20
            anchors.leftMargin: 20

        }
        //кнопка закрытия
        Button {
            id: closeBtn
            x: 598
            y: 0
            width: 40
            height: 40
            text: qsTr("Button")
            anchors.right: parent.right
            anchors.rightMargin: 0
            z: 2
            display: AbstractButton.IconOnly
            icon.height: 40
            icon.width: 40
            icon.color: closeBtn.hovered ? "#432464" : "#ffffff"
            icon.source: "icons/icons8-close.svg"
            flat: true

            background: Rectangle {
                color: closeBtn.hovered ? "#a283c2" : "#432464"
                opacity: closeBtn.hovered ? 1 : 0.5
                // добавляем анимацию затухания
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            onClicked: {
                mainWindow.close()
            }


        }
        //кнопка сворачивания
        Button {
            id: minimizeBtn
            x: 555
            y: 0
            width: 43
            height: 40
            text: qsTr("Button")
            anchors.right: closeBtn.left
            z: 2
            anchors.rightMargin: 0
            icon.color: minimizeBtn.hovered ? "#432464" : "#ffffff"
            icon.height: 4
            icon.source: "icons/minimize.svg"
            icon.width: 30
            flat: true
            display: AbstractButton.IconOnly
            background: Rectangle {
                color: minimizeBtn.hovered ? "#a283c2" : "#432464"
                opacity: minimizeBtn.hovered ? 1 : 0.5
                // добавляем анимацию затухания
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            onClicked: {
                mainWindow.showMinimized()
            }

        }
        //драг, чтобы окно можно было перемащать
        Item {
            id: _dragHandler
            anchors.fill: parent
            z: 1
            DragHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                grabPermissions:  PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType | PointerHandler.ApprovesTakeOverByAnything
                onActiveChanged: if (active) mainWindow.startSystemMove()
            }
        }
    }
    //прямоугольник вокруг изображения
    Rectangle {
        id: imgBorder
        color: "#00ffffff"
        radius: 5
        border.color: "#432464"
        border.width: 5
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.rightMargin: 108
        anchors.bottomMargin: 117
        anchors.topMargin: 20
        anchors.leftMargin: 20
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        //виджет для показа изображения
        Image {
            id: image
            anchors.fill: parent
            z: 1
            anchors.rightMargin: 4
            anchors.leftMargin: 4
            anchors.bottomMargin: 4
            anchors.topMargin: 4
            fillMode: Image.PreserveAspectFit
        }
        //область для обработки перетаскивания файла
        DropArea{
            property int maxImageWidth: 400

            id: dropImg
            anchors.fill: parent
            onDropped: function(event) {
                // если не картинка, не принимаем
                if (!(/\.(png|jpe?g|bmp)$/i.test(event.urls[0]))){
                    image.source = ""
                    animationSequence.start()
                    return
                }

               image.source = event.urls[0]
                //блок для установки соотношения сторон приложения по соотношению сторон картинки
                mainWindow.aspectRatio = image.paintedWidth / image.paintedHeight
                var delta_image_width = image.paintedWidth - image.width
                var delta_image_height = image.paintedHeight - image.height

                mainWindow.width += Math.min(0, image.paintedWidth - image.width);
                mainWindow.height += Math.min(0, image.paintedHeight - image.height);


                areaSlider.value = 0
                blurSlider.value = 33
            }
        }
        //иконка перетащи сюда
        Button {
            id: iconDragNDrop
            text: qsTr("Button")
            anchors.fill: parent
            hoverEnabled: false
            enabled: false
            anchors.rightMargin: 20
            anchors.leftMargin: 20
            anchors.bottomMargin: 20
            anchors.topMargin: 20
            z: 0
            icon.color: "#ffffff"
            icon.height: 100
            icon.width: 100
            icon.source: "icons/drag_drop_icon_207456.svg"
            display: AbstractButton.IconOnly
            flat: true
        }

    }
    //анимация при неправильных действиях
    ParallelAnimation {
        id: animationSequence

        PropertyAnimation {
            id: iconAnimation
            target: iconDragNDrop
            property: "icon.color"
            from: 'white'
            to: 'red'
            duration: 250
        }

        PropertyAnimation {
            id: borderAnimation
            target: imgBorder
            from: '#432464'
            to: "red"
            property: "border.color"
            duration: 250
        }

        onFinished: {
            // Запускаем обратную анимацию
            animationSequenceBackward.start()
        }
    }

    // Обратная цепочка анимации
    ParallelAnimation {
        id: animationSequenceBackward

        PropertyAnimation {
            target: iconDragNDrop
            property: "icon.color"
            to: 'white'
            duration: 250
        }

        PropertyAnimation {
            target: imgBorder
            to: "#432464"
            property: "border.color"
            duration: 250
        }

        onFinished: {
            // Возвращаем свойства в исходное состояние
            iconDragNDrop.icon.color = 'white'
            imgBorder.border.color = '#432464'
        }
    }

    //кнопка сохранить
    Button {
        id: saveBtn
        y: 534
        height: 32
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        flat: true
        anchors.rightMargin: 20
        anchors.bottomMargin: 20
        anchors.leftMargin: 20
        Layout.rightMargin: 40
        Layout.leftMargin: 40
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBaseline

        contentItem: Text {
            text: "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\np, li { white-space: pre-wrap; }\nhr { height: 1px; border-width: 0; }\nli.unchecked::marker { content: \"\\2610\"; }\nli.checked::marker { content: \"\\2612\"; }\n</style></head><body style=\" font-family:'Segoe UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-family:'Segoe UI Black'; font-size:12pt;\">СОХРАНИТЬ</span></p></body></html>"
            opacity: enabled ? 1.0 : 0.3
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.RichText
        }

        background: Rectangle {
            radius: 16
            border.color: "#ffffff"
            border.width: saveBtn.hovered ? 1 : 0
            opacity: saveBtn.hovered ? 0.5 : 1

            // добавляем анимацию затухания
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
            color: "#432464"
        }
        //запускаем функцию из python
        onClicked: {
            if (image.source == ""){
                animationSequence.start()
                return
            }
            backend.handle_save_button_clicked()
        }
    }
    //кнопка размытия
    Button {
        id: blurBtn
        y: 490
        height: 32
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: saveBtn.top
        flat: true
        display: AbstractButton.TextOnly
        anchors.rightMargin: 20
        anchors.leftMargin: 20
        anchors.bottomMargin: 10
        Layout.rightMargin: 40
        Layout.leftMargin: 40
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBaseline

        contentItem: Text {
            text: "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\np, li { white-space: pre-wrap; }\nhr { height: 1px; border-width: 0; }\nli.unchecked::marker { content: \"\\2610\"; }\nli.checked::marker { content: \"\\2612\"; }\n</style></head><body style=\" font-family:'Segoe UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-family:'Segoe UI Black'; font-size:12pt;\">РАЗМЫТЬ</span></p></body></html>"
            opacity: enabled ? 1.0 : 0.3
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.RichText
        }

        background: Rectangle {
            radius: 16
            border.color: "#ffffff"
            border.width: blurBtn.hovered ? 1 : 0
            opacity: blurBtn.hovered ? 0.5 : 1

            // добавляем анимацию затухания
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
            color: "#432464"
        }
        //запускаем функцию питон
        onClicked: {
            if (image.source == ""){
                animationSequence.start()
                return
            }
            backend.processImage(image.source)
        }
    }
    //текстовые пометки
    Text {
        id: textBlur
        x: 354
        rotation: 270
        color: "#ffffff"
        text: "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\np, li { white-space: pre-wrap; }\nhr { height: 1px; border-width: 0; }\nli.unchecked::marker { content: \"\\2610\"; }\nli.checked::marker { content: \"\\2612\"; }\n</style></head><body style=\" font-family:'Segoe UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-family:'Segoe UI Semibold'; font-size:10pt;\">СТЕПЕНЬ РАЗМЫТИЯ</span></p></body></html>"
        anchors.verticalCenter: blurSlider.verticalCenter
        anchors.right: blurSlider.left
        font.pixelSize: 12
        anchors.rightMargin: -55
        textFormat: Text.RichText
    }

    Text {
        id: textRadius
        x: 434
        color: "#ffffff"
        text: "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\np, li { white-space: pre-wrap; }\nhr { height: 1px; border-width: 0; }\nli.unchecked::marker { content: \"\\2610\"; }\nli.checked::marker { content: \"\\2612\"; }\n</style></head><body style=\" font-family:'Segoe UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-family:'Segoe UI Semibold'; font-size:10pt;\">− РАДИУС +</span></p></body></html>"
        anchors.verticalCenter: areaSlider.verticalCenter
        anchors.right: areaSlider.left
        font.pixelSize: 12
        anchors.rightMargin: -25
        textFormat: Text.RichText
        rotation: 270
    }
    //передаем информацию в питон
    Connections {
        target: backend
        function onGetImageSource(url) {
            image.source = url
        }

    }


}
