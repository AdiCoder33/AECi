# Entry Detail Screen Edit Implementation Plan

## Changes Needed:

### 1. Convert to StatefulWidget
- Change from `ConsumerWidget` to `ConsumerStatefulWidget`
- Add `_EntryDetailScreenState` class

### 2. Add State Variables & Controllers

**For Surgical Records:**
- `_recordPatientNameController`
- `_recordAgeController`
- `_recordDiagnosisController`
- `_recordAssistedByController`
- `_recordDurationController`
- `_recordSurgicalNotesController`
- `_recordComplicationsController`
- `_recordSex` (String?)
- `_recordSurgery` (String?)
- `_recordRightEye` (String?)
- `_recordLeftEye` (String?)
- `_existingRecordPreOpImagePaths` (List<String>)
- `_existingRecordPostOpImagePaths` (List<String>)
- `_newRecordPreOpImages` (List<File>)
- `_newRecordPostOpImages` (List<File>)
- `_existingVideosPaths` (List<String>)
- `_newVideos` (List<File>)

**For Learning Module:**
- `_learningStepController`
- `_consultantController`
- `_learningSurgery` (String?)
- `_existingVideosPaths` (List<String>)
- `_newVideos` (List<File>)

**For Atlas/Images:**
- `_atlasDiagnosisController`
- `_atlasBriefController`
- `_mediaType` (String?)
- `_existingImagePaths` (List<String>)
- `_newImages` (List<File>)

**Common:**
- `_patientController` (UID)
- `_mrnController`

### 3. Add Methods

**Loading:**
- `_loadEntryForEditing()` - Pre-fill controllers based on module type

**Saving:**
- `_saveEntry()` - Upload media and update entry

**UI Builders:**
- `_buildEditForm()` - Show editable form based on module type
- `_buildTextField()` - Reusable text field
- `_buildSexDropdown()` - Sex options dropdown
- `_buildSurgeryDropdown()` - Surgery options for records
- `_buildLearningSurgeryDropdown()` - Surgery options for learning
- `_buildLearningStepDropdown()` - Step options for learning
- `_buildEyeDropdownRow()` - Left/Right eye options
- `_ImagePickerSection` - Image picker widget
- `_VideoPickerSection` - Video picker widget

### 4. Field Mapping (Entry Form → Entry Detail)

**Surgical Records:**
- Patient name
- UID (patientUniqueId)
- MRN
- Age
- Sex dropdown (Male/Female)
- Diagnosis
- Surgery dropdown
- Assisted by
- Duration
- Right eye dropdown
- Left eye dropdown
- Surgical notes (multiline)
- Complications (multiline)
- Pre-op images (with picker)
- Post-op images (with picker)
- Videos (with picker)

**Learning Module:**
- Surgery dropdown (Name of the surgery)
- Step dropdown (Name of the step)
- Consultant name
- Videos (with picker)

**Atlas/Images:**
- Type of media dropdown
- Diagnosis
- Brief description
- Images (with picker)

### 5. Edit Button Logic
- Show "Edit" button only when `canEdit = true`
- Toggle between view mode and edit mode using StateProvider
- Save/Cancel buttons in edit mode
