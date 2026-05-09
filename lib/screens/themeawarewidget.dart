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

  const ThemeAwareWidget({super.key, required this.child});

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
  final TextScaler? textScaler;

  const ThemeAwareText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    final themeStyle =
        Theme.of(
          context,
        ).textTheme.bodyMedium; // Use theme's default text style
    return Text(
      text,
      style: themeStyle?.merge(style), // Merge theme style with custom style
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textScaler: textScaler,
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
      shape:
          shape ??
          theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
      style:
          style ??
          ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.12,
            ),
            disabledForegroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.38,
            ),
            shadowColor: theme.colorScheme.shadow,
            elevation: 2,
            textStyle: theme.textTheme.labelLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding:
                padding ??
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
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

/// AppBar that automatically adapts to theme changes
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation ?? theme.appBarTheme.elevation,
      shadowColor: shadowColor ?? theme.appBarTheme.shadowColor,
      shape: shape ?? theme.appBarTheme.shape,
      backgroundColor:
          backgroundColor ??
          theme.appBarTheme.backgroundColor ??
          theme.colorScheme.primary,
      foregroundColor:
          theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
      iconTheme: iconTheme ?? theme.appBarTheme.iconTheme ?? theme.iconTheme,
      actionsIconTheme:
          actionsIconTheme ??
          theme.appBarTheme.actionsIconTheme ??
          theme.iconTheme,
      primary: primary,
      excludeHeaderSemantics: excludeHeaderSemantics,
      titleSpacing: titleSpacing ?? NavigationToolbar.kMiddleSpacing,
      toolbarOpacity: toolbarOpacity,
      bottomOpacity: bottomOpacity,
      bottom: bottom,
      leadingWidth: leadingWidth,
      toolbarTextStyle:
          toolbarTextStyle ??
          theme.appBarTheme.toolbarTextStyle ??
          theme.textTheme.titleLarge,
      titleTextStyle:
          titleTextStyle ??
          theme.appBarTheme.titleTextStyle ??
          theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
      systemOverlayStyle:
          systemOverlayStyle ?? theme.appBarTheme.systemOverlayStyle,
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
      drawerScrimColor:
          drawerScrimColor ??
          theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
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
