// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get addHostelTitle => 'Ajouter une nouvelle auberge';

  @override
  String get hostelName => 'Nom de l\'auberge';

  @override
  String get location => 'Emplacement';

  @override
  String get price => 'Prix';

  @override
  String get description => 'Description';

  @override
  String get amenities => 'Équipements';

  @override
  String get addAmenity => 'Ajouter un équipement';

  @override
  String get rooms => 'Chambres';

  @override
  String get addRoom => 'Ajouter une chambre';

  @override
  String get roomNumber => 'Numéro de chambre';

  @override
  String get roomType => 'Type de chambre';

  @override
  String get singleRoom => 'Chambre simple';

  @override
  String get doubleRoom => 'Chambre double';

  @override
  String get pickImage => 'Choisir une image';

  @override
  String get noImage => 'Pas d\'image';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get images => 'Images';

  @override
  String get pickImages => 'Choisir des images';

  @override
  String get noImagesSelected => 'Aucune image sélectionnée.';

  @override
  String get review => 'Revoir';

  @override
  String get submit => 'SOUMETTRE';

  @override
  String get next => 'SUIVANT';

  @override
  String get back => 'RETOUR';

  @override
  String get saveAsDraft => 'Enregistrer comme brouillon';

  @override
  String get draftSaved => 'Brouillon enregistré!';

  @override
  String get draftRestored => 'Brouillon restauré!';

  @override
  String get clear => 'Effacer';

  @override
  String get success => 'Succès!';

  @override
  String get hostelUploaded => 'Auberge et chambres téléchargées avec succès!';

  @override
  String get required => 'Requis';

  @override
  String get duplicateRoomNumber => 'Numéro de chambre en double';

  @override
  String get pleaseAddRoom => 'Veuillez ajouter au moins une chambre.';

  @override
  String get pleaseSelectImage => 'Veuillez sélectionner au moins une image.';

  @override
  String get pickOnMap => 'Choisir sur la carte';

  @override
  String get pickHostelLocation => 'Choisir l\'emplacement de l\'auberge';

  @override
  String get select => 'Sélectionner';

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
