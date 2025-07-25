// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addHostelTitle => 'Add New Hostel';

  @override
  String get hostelName => 'Hostel Name';

  @override
  String get location => 'Location';

  @override
  String get price => 'Price';

  @override
  String get description => 'Description';

  @override
  String get amenities => 'Amenities';

  @override
  String get addAmenity => 'Add Amenity';

  @override
  String get rooms => 'Rooms';

  @override
  String get addRoom => 'Add Room';

  @override
  String get roomNumber => 'Room Number';

  @override
  String get roomType => 'Room Type';

  @override
  String get singleRoom => 'Single Room';

  @override
  String get doubleRoom => 'Double Room';

  @override
  String get pickImage => 'Pick Image';

  @override
  String get noImage => 'No image';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get images => 'Images';

  @override
  String get pickImages => 'Pick Images';

  @override
  String get noImagesSelected => 'No images selected.';

  @override
  String get review => 'Review';

  @override
  String get submit => 'SUBMIT';

  @override
  String get next => 'NEXT';

  @override
  String get back => 'BACK';

  @override
  String get saveAsDraft => 'Save as Draft';

  @override
  String get draftSaved => 'Draft saved!';

  @override
  String get draftRestored => 'Draft restored!';

  @override
  String get clear => 'Clear';

  @override
  String get success => 'Success!';

  @override
  String get hostelUploaded => 'Hostel and rooms uploaded successfully!';

  @override
  String get required => 'Required';

  @override
  String get duplicateRoomNumber => 'Duplicate room number';

  @override
  String get pleaseAddRoom => 'Please add at least one room.';

  @override
  String get pleaseSelectImage => 'Please select at least one image.';

  @override
  String get pickOnMap => 'Pick on Map';

  @override
  String get pickHostelLocation => 'Pick Hostel Location';

  @override
  String get select => 'Select';

  @override
  String get noRoomsFound => 'No rooms found for this hostel.';

  @override
  String get editRoom => 'Edit Room';

  @override
  String get type => 'Type';

  @override
  String get tenant => 'Tenant';

  @override
  String get roomUpdated => 'Room updated.';

  @override
  String get roomAdded => 'Room added.';

  @override
  String get error => 'Error';

  @override
  String get add => 'Add';

  @override
  String get deleteRoom => 'Delete Room';

  @override
  String get deleteRoomConfirm => 'Are you sure you want to delete this room?';

  @override
  String get delete => 'Delete';

  @override
  String get roomDeleted => 'Room deleted.';

  @override
  String get undo => 'Undo';

  @override
  String get markAsVacant => 'Mark as Vacant';

  @override
  String get markAsOccupied => 'Mark as Occupied';

  @override
  String markRoomConfirm(Object status) {
    return 'Are you sure you want to mark this room as $status?';
  }

  @override
  String get vacant => 'Vacant';

  @override
  String get occupied => 'Occupied';

  @override
  String get yes => 'Yes';

  @override
  String roomMarkedAs(Object status) {
    return 'Room marked as $status.';
  }

  @override
  String get exportedCsv => 'Exported to CSV.';

  @override
  String get roomManagement => 'Room Management';

  @override
  String get selectHostel => 'Select a hostel';

  @override
  String get selectHostelToViewRooms => 'Select a hostel to view its rooms.';

  @override
  String get searchByRoomNumberOrType => 'Search by room number or type';

  @override
  String get all => 'All';

  @override
  String get export => 'Export';

  @override
  String get deselectRoom => 'Deselect room';

  @override
  String get selectRoom => 'Select room';

  @override
  String get na => 'N/A';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get deleteRooms => 'Delete Rooms';

  @override
  String get deleteSelectedRoomsConfirm =>
      'Are you sure you want to delete the selected rooms?';

  @override
  String get errorDeletingRoom => 'Error deleting room';

  @override
  String get selectedRoomsDeleted => 'Selected rooms deleted.';

  @override
  String get markSelectedAsVacant => 'Mark Selected as Vacant';

  @override
  String get errorUpdatingRoom => 'Error updating room';

  @override
  String get selectedRoomsMarkedAsVacant => 'Selected rooms marked as vacant.';

  @override
  String get tenantOptional => 'Tenant (Optional)';
}
