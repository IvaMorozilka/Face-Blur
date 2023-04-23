import cv2
import face_recognition

def blur_faces(image):
    image = face_recognition.load_image_file(image)
    face_location = face_recognition.face_locations(image)

    for face in face_location:
        top, right, bottom, left = face
        face_image = image[top:bottom, left:right]
        face_image = cv2.GaussianBlur(face_image, (99, 99), 30)
        image[top:bottom, left:right] = face_image

    return image
