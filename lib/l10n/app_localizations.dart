import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @addHostelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Hostel'**
  String get addHostelTitle;

  /// No description provided for @hostelName.
  ///
  /// In en, this message translates to:
  /// **'Hostel Name'**
  String get hostelName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @addAmenity.
  ///
  /// In en, this message translates to:
  /// **'Add Amenity'**
  String get addAmenity;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// No description provided for @roomNumber.
  ///
  /// In en, this message translates to:
  /// **'Room Number'**
  String get roomNumber;

  /// No description provided for @roomType.
  ///
  /// In en, this message translates to:
  /// **'Room Type'**
  String get roomType;

  /// No description provided for @singleRoom.
  ///
  /// In en, this message translates to:
  /// **'Single Room'**
  String get singleRoom;

  /// No description provided for @doubleRoom.
  ///
  /// In en, this message translates to:
  /// **'Double Room'**
  String get doubleRoom;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get noImage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @pickImages.
  ///
  /// In en, this message translates to:
  /// **'Pick Images'**
  String get pickImages;

  /// No description provided for @noImagesSelected.
  ///
  /// In en, this message translates to:
  /// **'No images selected.'**
  String get noImagesSelected;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT'**
  String get submit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get back;

  /// No description provided for @saveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get saveAsDraft;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved!'**
  String get draftSaved;

  /// No description provided for @draftRestored.
  ///
  /// In en, this message translates to:
  /// **'Draft restored!'**
  String get draftRestored;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @hostelUploaded.
  ///
  /// In en, this message translates to:
  /// **'Hostel and rooms uploaded successfully!'**
  String get hostelUploaded;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @duplicateRoomNumber.
  ///
  /// In en, this message translates to:
  /// **'Duplicate room number'**
  String get duplicateRoomNumber;

  /// No description provided for @pleaseAddRoom.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one room.'**
  String get pleaseAddRoom;

  /// No description provided for @pleaseSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one image.'**
  String get pleaseSelectImage;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMap;

  /// No description provided for @pickHostelLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick Hostel Location'**
  String get pickHostelLocation;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @noRoomsFound.
  ///
  /// In en, this message translates to:
  /// **'No rooms found for this hostel.'**
  String get noRoomsFound;

  /// No description provided for @editRoom.
  ///
  /// In en, this message translates to:
  /// **'Edit Room'**
  String get editRoom;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @roomUpdated.
  ///
  /// In en, this message translates to:
  /// **'Room updated.'**
  String get roomUpdated;

  /// No description provided for @roomAdded.
  ///
  /// In en, this message translates to:
  /// **'Room added.'**
  String get roomAdded;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @deleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete Room'**
  String get deleteRoom;

  /// No description provided for @deleteRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this room?'**
  String get deleteRoomConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @roomDeleted.
  ///
  /// In en, this message translates to:
  /// **'Room deleted.'**
  String get roomDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @markAsVacant.
  ///
  /// In en, this message translates to:
  /// **'Mark as Vacant'**
  String get markAsVacant;

  /// No description provided for @markAsOccupied.
  ///
  /// In en, this message translates to:
  /// **'Mark as Occupied'**
  String get markAsOccupied;

  /// No description provided for @markRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this room as {status}?'**
  String markRoomConfirm(Object status);

  /// No description provided for @vacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get vacant;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupied;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @roomMarkedAs.
  ///
  /// In en, this message translates to:
  /// **'Room marked as {status}.'**
  String roomMarkedAs(Object status);

  /// No description provided for @exportedCsv.
  ///
  /// In en, this message translates to:
  /// **'Exported to CSV.'**
  String get exportedCsv;

  /// No description provided for @roomManagement.
  ///
  /// In en, this message translates to:
  /// **'Room Management'**
  String get roomManagement;

  /// No description provided for @selectHostel.
  ///
  /// In en, this message translates to:
  /// **'Select a hostel'**
  String get selectHostel;

  /// No description provided for @selectHostelToViewRooms.
  ///
  /// In en, this message translates to:
  /// **'Select a hostel to view its rooms.'**
  String get selectHostelToViewRooms;

  /// No description provided for @searchByRoomNumberOrType.
  ///
  /// In en, this message translates to:
  /// **'Search by room number or type'**
  String get searchByRoomNumberOrType;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @deselectRoom.
  ///
  /// In en, this message translates to:
  /// **'Deselect room'**
  String get deselectRoom;

  /// No description provided for @selectRoom.
  ///
  /// In en, this message translates to:
  /// **'Select room'**
  String get selectRoom;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @deleteRooms.
  ///
  /// In en, this message translates to:
  /// **'Delete Rooms'**
  String get deleteRooms;

  /// No description provided for @deleteSelectedRoomsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected rooms?'**
  String get deleteSelectedRoomsConfirm;

  /// No description provided for @errorDeletingRoom.
  ///
  /// In en, this message translates to:
  /// **'Error deleting room'**
  String get errorDeletingRoom;

  /// No description provided for @selectedRoomsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected rooms deleted.'**
  String get selectedRoomsDeleted;

  /// No description provided for @markSelectedAsVacant.
  ///
  /// In en, this message translates to:
  /// **'Mark Selected as Vacant'**
  String get markSelectedAsVacant;

  /// No description provided for @errorUpdatingRoom.
  ///
  /// In en, this message translates to:
  /// **'Error updating room'**
  String get errorUpdatingRoom;

  /// No description provided for @selectedRoomsMarkedAsVacant.
  ///
  /// In en, this message translates to:
  /// **'Selected rooms marked as vacant.'**
  String get selectedRoomsMarkedAsVacant;

  /// No description provided for @tenantOptional.
  ///
  /// In en, this message translates to:
  /// **'Tenant (Optional)'**
  String get tenantOptional;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
