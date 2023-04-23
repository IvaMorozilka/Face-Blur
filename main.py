# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication, QPixmap, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QThread
from PySide6.QtWidgets import QApplication, QFileDialog, QMessageBox
from PySide6.QtQuick import QQuickImageProvider
import cv2
import face_recognition
import qimage2ndarray

class ImageProcessingThread(QThread):
    processed_image = Signal(QImage)

    def __init__(self, image_path, blur_slider_value, area_slider_value,parent=None):
        super().__init__(parent)
        self.image_path = image_path
        self.blur_value = blur_slider_value
        self.area_offset = area_slider_value

    def run(self):
        image = face_recognition.load_image_file(self.image_path.replace('image://blur_image/', ''))
        face_location = face_recognition.face_locations(image)

        for face in face_location:
            top, right, bottom, left = face
            face_image = image[top - self.area_offset:bottom + self.area_offset, left - self.area_offset:right + self.area_offset]
            face_image = cv2.GaussianBlur(face_image, (self.blur_value, self.blur_value), 30)
            image[top - self.area_offset:bottom + self.area_offset, left - self.area_offset:right + self.area_offset] = face_image

        scale_percent = 99
        width = int(image.shape[1] * scale_percent / 100)
        height = int(image.shape[0] * scale_percent / 100)
        dim = (width, height)
#        image = cv2.resize(image, dim)
        q_image = qimage2ndarray.array2qimage(image)
        self.processed_image.emit(q_image)

class ColorImageProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.Pixmap)

    def requestPixmap(self, id, size, requestedSize):
        return QPixmap.fromImage(self.processed_image)

class MainWindow(QObject):
    def __init__(self, engine):
        QObject.__init__(self)
        self.engine = engine
        self.blur_slider_value = 33
        self.area_slider_value = 0


    getImageSource = Signal(str)
    getBlurSliderValue = Signal(int)
    getAreaSliderValue = Signal(int)
    saveImage = Signal(QImage)

    @Slot()
    def handle_save_button_clicked(self):
        dialog = QFileDialog()
        options = QFileDialog.Options()
        dialog.setNameFilter("")
        dialog.setAcceptMode(QFileDialog.AcceptSave)
        fileName, _ = QFileDialog.getSaveFileName(
            dialog, "Save Image", r"H:\Image", "PNG Files (*.png);;JPEG Files (*.jpg);;BMP Files (*.bmp)", options=options
        )
        if (fileName):
            self.color_image_provider.processed_image.save(fileName)

    @Slot(int)
    def area_slider_moved(self, value):
        self.area_slider_value = value
        self.getAreaSliderValue.emit(value)

    @Slot(int)
    def blur_slider_moved(self, value):
        self.blur_slider_value = value
        self.getBlurSliderValue.emit(value)

    @Slot(str)
    def processImage(self, source):
        cutted_path = source.replace("file:///", "")
        path = f'image://blur_image/{cutted_path}'
        a, b = self.blur_slider_value, self.area_slider_value
        self.image_processing_thread = ImageProcessingThread(cutted_path, self.blur_slider_value, self.area_slider_value)
        self.image_processing_thread.processed_image.connect(self.handle_processed_image)
        self.image_processing_thread.start()

    @Slot(QImage)
    def handle_processed_image(self, image):
        self.color_image_provider = ColorImageProvider()
        self.color_image_provider.processed_image = image
        self.engine.addImageProvider("blur_image", self.color_image_provider)
        cutted_path = self.image_processing_thread.image_path.replace("file:///", "")
        path = f'image://blur_image/{cutted_path}'
        self.getImageSource.emit(path)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).resolve().parent / "main.qml"

    main = MainWindow(engine)
    context = engine.rootContext()
    context.setContextProperty("backend", main)

    engine.addImageProvider("blur_image", ColorImageProvider())
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
