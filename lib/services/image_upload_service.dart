import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  factory ImageUploadService() => _instance;

  ImageUploadService._internal();
  static final ImageUploadService _instance = ImageUploadService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final Dio _dio = Dio();

  // ⚠️ IMPORTANT: Replace with your ImgBB API key from https://imgbb.com/
  static const String _imgbbApiKey = 'e3502679ef9e15f3c59f71a6e9c58202';

  /// Pick an image from the gallery
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress to 85% quality
      );
      return image;
    } catch (e) {
      throw 'Failed to pick image: $e';
    }
  }

  /// Pick multiple images from the gallery
  Future<List<XFile>> pickMultipleImages({int maxImages = 1}) async {
    try {
      // Enforce minimum limit of 2 for image picker (iOS/Android requirement)
      final limit = maxImages < 2 ? 2 : maxImages;
      
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: limit,
      );
      return images;
    } catch (e) {
      throw 'Failed to pick images: $e';
    }
  }

  /// Upload a single image to ImgBB (FREE service)
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage({
    required XFile imageFile,
    required String folder, // e.g., 'products', 'services', 'user_profiles'
    required String userId,
    String? customFileName,
  }) async {
    try {
      if (_imgbbApiKey == 'YOUR_IMGBB_API_KEY_HERE') {
        throw 'ImgBB API key not configured. Get it from https://imgbb.com/';
      }

      final FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: customFileName ?? imageFile.name,
        ),
      });

      final Response response = await _dio.post(
        'https://api.imgbb.com/1/upload?key=$_imgbbApiKey',
        data: formData,
      );

      if (response.statusCode == 200) {
        final String imageUrl = response.data['data']['url'];
        return imageUrl;
      } else {
        throw 'Upload failed with status code: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  /// Upload multiple images to ImgBB
  /// Returns a list of download URLs
  Future<List<String>> uploadMultipleImages({
    required List<XFile> imageFiles,
    required String folder,
    required String userId,
  }) async {
    try {
      final List<String> downloadUrls = [];

      for (final imageFile in imageFiles) {
        final url = await uploadImage(
          imageFile: imageFile,
          folder: folder,
          userId: userId,
        );
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      throw 'Failed to upload images: $e';
    }
  }
}
