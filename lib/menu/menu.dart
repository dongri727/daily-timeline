import "package:flutter/material.dart";
import '../bloc_provider.dart';
import '../distance/widget.dart';
import 'menu_data.dart';
import 'menu_section.dart';

/// The Base Page of the Distance App.
/// the card-sections for accessing the main events on the Distance,
class MainMenuWidget extends StatefulWidget {
  const MainMenuWidget({Key? key}) : super(key: key);

  @override
  MainMenuWidgetState createState() => MainMenuWidgetState();
}

class MainMenuWidgetState extends State<MainMenuWidget> {

  /// [MenuData] is a wrapper object for the data of each Card section.
  /// This data is loaded from the asset bundle during [initState()]
  final MenuData _menu = MenuData();

  /// Helper function which sets the [MenuItemData] for the [DistanceWidget].
  /// This will trigger a transition from the current menu to the Distance,
  /// thus the push on the [Navigator], and by providing the [item] as
  /// a parameter to the [DistanceWidget] constructor, this widget will know
  /// where to scroll to.
  navigateToDistance(MenuItemData item) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (BuildContext context) =>
          DistanceWidget(item, BlocProvider.getDistance(context)),
    ));
  }

  @override
  initState() {
    super.initState();

    /// The [_menu] loads a JSON file that's stored in the assets folder.
    /// This asset provides all the necessary information for the cards,
    /// such as labels, background colors,
    /// and for each element in the expanded card, the relative position on the [Distance].
    _menu.loadFromBundle("assets/menu.json").then((bool success) {
      if (success) setState(() {}); // Load the menu.
    });
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;

    List<Widget> tail = [];

    tail
        .addAll(_menu.sections
        .map<Widget>((MenuSectionData section) => Container(
        margin: const EdgeInsets.only(top: 20.0),
        child: MenuSection(
          section.label,
          section.backgroundColor,
          section.textColor,
          section.items,
          navigateToDistance,
        )))
        .toList(growable: false));

    /// A [SingleChildScrollView] is used to create a scrollable view for the main menu.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voyager II"),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: devicePadding.top),
        child: SingleChildScrollView(
            padding:
            const EdgeInsets.only(top: 20.0, left: 20, right: 20, bottom: 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[] + tail)),
      ),
    );
  }
}