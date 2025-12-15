# Changelog

## [1.0.0] - 2024-12-12

### Added
- Initial release of LiveDB (Cloud Database & Storage)
- `LiveDB` singleton client with `db` and `storage` modules
- **Cloud Database**:
  - `createProject()`
  - `add()` documents
  - `get()` documents with filtering
  - `delete()` documents
- **Cloud Storage**:
  - `uploadFile()` - Multipart file upload
  - `uploadBytes()` - Base64 upload
  - `uploadLargeFile()` - Chunked upload
  - `deleteFile()`
- `LiveDBConfig` for customization
- Comprehensive documentation and examples
