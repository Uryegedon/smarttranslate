import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/themeprovider.dart';
 // Adjust the import to match your folder structure

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final availableColors = <MaterialColor>[
      Colors.teal,
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
    ];

    Widget buildColorPicker(String title, MaterialColor selectedColor, Function(MaterialColor) onColorSelected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: themeProvider.highlightTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableColors.map((color) {
              bool isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 24,
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Theme Settings",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dark Mode",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: themeProvider.toggleDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Font Color Picker
            buildColorPicker(
              "Font Color",
              themeProvider.fontColor,
              themeProvider.changeFontColor,
            ),

            // Highlight Color Picker
            buildColorPicker(
              "Highlight Color",
              themeProvider.highlightColor,
              themeProvider.changeHighlightColor,
            ),
          ],
        ),
      ),
    );
  }
}
