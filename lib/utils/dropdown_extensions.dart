import 'package:heliumapp/data/models/drop_down_item.dart';

extension DropDownItemsExtension on List<String> {
  List<DropDownItem<String>> toDropDownItems() {
    return map((item) => DropDownItem(id: indexOf(item), value: item)).toList();
  }
}
