import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/features/addresses/data/models/address_model.dart';
import 'package:laundry_app/features/addresses/domain/entities/address.dart';
import 'package:laundry_app/features/addresses/presentation/widgets/address_form_fields.dart';
import 'package:latlong2/latlong.dart' show LatLng;

void main() {
  const saved = Address(
    id: 'a1',
    city: 'Abu Dhabi',
    area: 'Al Reem',
    building: 'Gate Tower 2',
    apartment: '1204',
    latitude: 24.4958,
    longitude: 54.4066,
  );

  test('editing an address keeps its pin', () {
    final data = AddressFormData(saved.toNewAddress());
    addTearDown(data.dispose);

    expect(data.location.value, const LatLng(24.4958, 54.4066));
    expect(data.toNewAddress().latitude, 24.4958);
    expect(data.toNewAddress().longitude, 54.4066);
  });

  test('a moved pin is what gets saved and sent', () {
    final data = AddressFormData(saved.toNewAddress());
    addTearDown(data.dispose);

    data.location.value = const LatLng(24.5, 54.41);
    final json = AddressModel.toJson(data.toNewAddress());

    expect(json['latitude'], 24.5);
    expect(json['longitude'], 54.41);
  });

  test('removing the pin clears the coordinates', () {
    final data = AddressFormData(saved.toNewAddress());
    addTearDown(data.dispose);

    data.location.value = null;
    final address = data.toNewAddress();

    expect(address.hasCoordinates, isFalse);
    expect(AddressModel.toJson(address)['latitude'], isNull);
  });

  test('a new address starts without a pin', () {
    final data = AddressFormData();
    addTearDown(data.dispose);

    expect(data.location.value, isNull);
  });
}
