// theme_aware_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemUiOverlayStyle
import 'package:flutter/gestures.dart'; // For DragStartBehavior

/// A collection of widgets that automatically adapt to the current theme
/// 
/// Usage:
/// 
/// ```dart
/// ThemeAwareWidget(
///   child: YourWidget(),
/// )
/// 
/// ThemeAwareText(
///   'Hello World',
///   style: TextStyle(fontWeight: FontWeight.bold),
/// )
/// ```

// ========================
// Core Theme-Aware Wrapper
// ========================

/// Wraps any widget to ensure proper theme inheritance
class ThemeAwareWidget extends StatelessWidget {
  final Widget child;
  
  const ThemeAwareWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Theme(
      data: theme,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium ?? const TextStyle(),
        child: child,
      ),
    );
  }
}

// ========================
// Text Components
// ========================

/// Text widget that automatically adapts to theme changes
class ThemeAwareText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final double? textScaleFactor;

  const ThemeAwareText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaleFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeStyle = Theme.of(context).textTheme.bodyMedium; // Use theme's default text style
    return Text(
      text,
      style: themeStyle?.merge(style), // Merge theme style with custom style
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }
}

// ========================
// Card Components
// ========================

/// Card widget that automatically adapts to theme changes
class ThemeAwareCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final bool borderOnForeground;
  
  const ThemeAwareCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.clipBehavior,
    this.borderOnForeground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.cardColor,
      elevation: elevation ?? theme.cardTheme.elevation ?? 1.0,
      margin: margin ?? theme.cardTheme.margin ?? const EdgeInsets.all(8.0),
      shadowColor: shadowColor ?? theme.cardTheme.shadowColor,
      shape: shape ?? theme.cardTheme.shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: clipBehavior ?? theme.cardTheme.clipBehavior ?? Clip.none,
      borderOnForeground: borderOnForeground,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

// ========================
// Button Components
// ========================

/// Elevated button that automatically adapts to theme changes
class ThemeAwareElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? padding;
  
  const ThemeAwareElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElevatedButton(
      onPressed: onPressed,
      style: style ?? ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.38),
        shadowColor: theme.colorScheme.shadow,
        elevation: 0,
        textStyle: theme.textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: padding ?? const EdgeInsets.symmetric(
          vertical: 16.0, horizontal: 32.0),
      ),
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

// ========================
// Icon Components
// ========================

/// Icon widget that automatically adapts to theme changes
class ThemeAwareIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;
  
  const ThemeAwareIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Icon(
      icon,
      size: size ?? theme.iconTheme.size,
      color: color ?? theme.iconTheme.color,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}

// ========================
// AppBar Component
// ========================

/// AppBar that automatically adapts to theme changes, supports gradient background
class ThemeAwareAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double toolbarOpacity;
  final double bottomOpacity;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;
  final TextStyle? toolbarTextStyle;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool useGradient;
  
  const ThemeAwareAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.backgroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
    this.bottom,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle ?? true,
      elevation: elevation ?? 0,
      shadowColor: shadowColor,
      shape: shape,
      backgroundColor: useGradient ? Colors.transparent : (backgroundColor ?? theme.appBarTheme.backgroundColor ?? primary),
      foregroundColor: Colors.white,
      iconTheme: iconTheme ?? const IconThemeData(color: Colors.white),
      actionsIconTheme: actionsIconTheme ?? const IconThemeData(color: Colors.white),
      primary: this.primary,
      excludeHeaderSemantics: excludeHeaderSemantics,
      titleSpacing: titleSpacing ?? NavigationToolbar.kMiddleSpacing,
      toolbarOpacity: toolbarOpacity,
      bottomOpacity: bottomOpacity,
      bottom: bottom,
      leadingWidth: leadingWidth,
      toolbarTextStyle: toolbarTextStyle,
      titleTextStyle: titleTextStyle ?? TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
      systemOverlayStyle: systemOverlayStyle ?? SystemUiOverlayStyle.light,
      flexibleSpace: useGradient ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              primary.withOpacity(0.85),
            ],
          ),
        ),
      ) : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ========================
// Scaffold Component
// ========================

/// Scaffold that automatically adapts to theme changes
class ThemeAwareScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final AlignmentDirectional persistentFooterAlignment;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? drawerScrimColor;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? padding;
  final String? restorationId;
  
  const ThemeAwareScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.drawer,
    this.endDrawer,
    this.drawerScrimColor,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.padding,
    this.restorationId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      persistentFooterAlignment: persistentFooterAlignment,
      drawer: drawer,
      endDrawer: endDrawer,
      drawerScrimColor: drawerScrimColor ?? theme.scaffoldBackgroundColor.withOpacity(0.5),
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      restorationId: restorationId,
    );
  }
}

// ========================
// Modern Bottom Navigation
// ========================

/// A modern floating bottom navigation bar
class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final unselected = theme.hintColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.translate_rounded,
                index: 0,
                label: 'Translate',
                primary: primary,
                unselected: unselected,
              ),
              _buildNavItem(
                icon: Icons.camera_alt_rounded,
                index: 1,
                label: 'Camera',
                primary: primary,
                unselected: unselected,
              ),
              _buildNavItem(
                icon: Icons.extension_rounded,
                index: 2,
                label: 'Games',
                primary: primary,
                unselected: unselected,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                index: 3,
                label: 'Profile',
                primary: primary,
                unselected: unselected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
    required Color primary,
    required Color unselected,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? primary : unselected,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}