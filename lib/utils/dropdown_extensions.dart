import 'package:heliumapp/data/models/drop_down_item.dart';

extension DropDownItemsExtension on List<String> {
  List<DropDownItem<String>> toDropDownItems() {
    return indexed.map((item) => DropDownItem(id: item.$1, value: item.$2)).toList();
  }
}
