# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path
from PySide6.QtGui import QPixmap, QImage, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QThread
from PySide6.QtWidgets import QApplication, QFileDialog
from PySide6.QtQuick import QQuickImageProvider
import cv2
import os
import face_recognition
import qimage2ndarray

# Определяем класс ImageProcessingThread, унаследованный от QThread.
class ImageProcessingThread(QThread):
    # Сигнал, который будет передаваться в главный поток с обработанным изображением.
    processed_image = Signal(QImage)

    # Метод инициализации класса ImageProcessingThread.
    def __init__(self, image_path, blur_slider_value, area_slider_value, parent=None):
        # Вызываем конструктор суперкласса.
        super().__init__(parent)
        # Устанавливаем атрибуты объекта.
        self.image_path = image_path
        self.blur_value = blur_slider_value
        self.area_offset = area_slider_value

    # Метод, который будет выполняться во вторичном потоке.
    def run(self):
        # Загружаем изображение с помощью библиотеки face_recognition.
        image = face_recognition.load_image_file(self.image_path.replace('image://blur_image/', ''))
        # Ищем координаты лиц на изображении.
        face_location = face_recognition.face_locations(image)

        # Для каждого найденного лица выполняем обработку.
        for face in face_location:
            top, right, bottom, left = face
            face_image = image[top - self.area_offset:bottom + self.area_offset, left - self.area_offset:right + self.area_offset]
            # Применяем фильтр GaussianBlur из библиотеки cv2.
            face_image = cv2.GaussianBlur(face_image, (self.blur_value, self.blur_value), 30)
            # Заменяем область лица на обработанное изображение.
            image[top - self.area_offset:bottom + self.area_offset, left - self.area_offset:right + self.area_offset] = face_image

        # Преобразуем изображение в формат QImage и передаем в главный поток через сигнал processed_image.
        q_image = qimage2ndarray.array2qimage(image)
        self.processed_image.emit(q_image)


# Определяем класс ColorImageProvider, унаследованный от QQuickImageProvider.
class ColorImageProvider(QQuickImageProvider):
    # Метод инициализации класса ColorImageProvider.
    def __init__(self):
        # Вызываем конструктор суперкласса.
        super().__init__(QQuickImageProvider.Pixmap)

    # Метод, который будет вызываться при запросе изображения.
    def requestPixmap(self, id, size, requestedSize):
        # Возвращаем изображение.
        return QPixmap.fromImage(self.processed_image)


# Определяем класс MainWindow, унаследованный от QObject.
class MainWindow(QObject):
    def __init__(self, engine):
        # Вызываем конструктор суперкласса.
        QObject.__init__(self)
        # Устанавливаем атрибуты объекта.
        self.engine = engine
        self.blur_slider_value = 33
        self.area_slider_value = 0

    # Объявляем сигналы.
    getImageSource = Signal(str)
    getBlurSliderValue = Signal(int)
    getAreaSliderValue = Signal(int)
    saveImage = Signal(QImage)

    @Slot()
    def handle_save_button_clicked(self):
        # Создаем диалоговое окно для сохранения файла.
        dialog = QFileDialog()
        options = QFileDialog.Options()
        dialog.setNameFilter("")
        dialog.setAcceptMode(QFileDialog.AcceptSave)
        # Устанавливаем фильтр для типов файлов.
        fileName, _ = QFileDialog.getSaveFileName(
            dialog, "Save Image", r"H:\Image", "PNG Files (*.png);;JPEG Files (*.jpg);;BMP Files (*.bmp)", options=options
        )
        if (fileName):
            # Сохраняем обработанное изображение.
            self.color_image_provider.processed_image.save(fileName)

    @Slot(int)
    def area_slider_moved(self, value):
        # Обработчик перемещения ползунка для выделения области.
        self.area_slider_value = value
        self.getAreaSliderValue.emit(value)

    @Slot(int)
    def blur_slider_moved(self, value):
        # Обработчик перемещения ползунка для настройки размытия.
        self.blur_slider_value = value
        self.getBlurSliderValue.emit(value)

    @Slot(str)
    def processImage(self, source):
        # Обработчик обработки изображения.
        cutted_path = source.replace("file:///", "")
        # Создаем поток для обработки изображения.
        self.image_processing_thread = ImageProcessingThread(cutted_path, self.blur_slider_value, self.area_slider_value)
        self.image_processing_thread.processed_image.connect(self.handle_processed_image)
        self.image_processing_thread.start()

    @Slot(QImage)
    def handle_processed_image(self, image):
        # Обработчик завершения обработки изображения.
        self.color_image_provider = ColorImageProvider()
        self.color_image_provider.processed_image = image
        self.engine.addImageProvider("blur_image", self.color_image_provider)
        cutted_path = self.image_processing_thread.image_path.replace("file:///", "")
        path = f'image://blur_image/{cutted_path}'
        self.getImageSource.emit(path)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    qml_file = Path('main.qml')
    #Path(__file__).resolve().parent / "main.qml"
    # Создаем экземпляр класса MainWindow и устанавливаем его в качестве контекста QML.
    main = MainWindow(engine)
    context = engine.rootContext()
    context.setContextProperty("backend", main)
    # Добавляем провайдер изображений в движок QQmlApplicationEngine.
    engine.addImageProvider("blur_image", ColorImageProvider())
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)
    # Запускаем цикл обработки событий приложения.
    app.setWindowIcon(QIcon('window.ico'))
    sys.exit(app.exec())
