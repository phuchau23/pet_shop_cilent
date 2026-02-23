import 'package:isar/isar.dart';
import 'cart_item_model.dart';

part 'cart_model.g.dart';

@collection
class CartModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int userId; // User ID để phân biệt cart của từng user

  @Name('items')
  final items = IsarLinks<CartItemModel>();

  CartModel();

  CartModel.create({required this.userId});
}
