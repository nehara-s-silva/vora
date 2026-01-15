import 'package:flutter/material.dart';
import 'package:vora/theme/app_theme.dart';

class VoraButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;
  final double? width;
  final double? height;

  const VoraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.color,
    this.isOutlined = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primaryGreen;

    return GestureDetector(
      onTap: (isLoading || !isEnabled) ? null : onPressed,
      child: Container(
        width: width,
        height: height ?? 48,
        decoration: BoxDecoration(
          gradient: isOutlined
              ? null
              : !isEnabled
              ? LinearGradient(
                  colors: [
                    buttonColor.withValues(alpha: 0.3),
                    buttonColor.withValues(alpha: 0.2),
                  ],
                )
              : LinearGradient(
                  colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
                ),
          color: isOutlined ? Colors.transparent : null,
          border: isOutlined ? Border.all(color: buttonColor, width: 2) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: !isEnabled ? [] : AppTheme.shadowMd,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOutlined ? buttonColor : Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: isOutlined ? buttonColor : Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isOutlined ? buttonColor : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class VoraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  const VoraCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusLarge,
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppTheme.radiusLarge,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class VoraTextField extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;

  const VoraTextField({
    super.key,
    this.hintText,
    this.controller,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.onChanged,
    this.validator,
    this.decoration,
  });

  @override
  State<VoraTextField> createState() => _VoraTextFieldState();
}

class _VoraTextFieldState extends State<VoraTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        style: AppTheme.bodyMedium,
        onChanged: widget.onChanged,
        decoration:
            widget.decoration ??
            InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTheme.bodySmall,
              border: InputBorder.none,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppTheme.primaryGreen)
                  : null,
              suffixIcon: widget.obscureText
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    )
                  : widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixIconTap,
                      child: Icon(
                        widget.suffixIcon,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
            ),
      ),
    );
  }
}

class VoraGradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? textStyle;

  const VoraGradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style:
            textStyle?.copyWith(color: Colors.white) ?? AppTheme.headingLarge,
      ),
    );
  }
}

class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color;

  const LoadingWidget({super.key, this.message, this.color});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(widget.message!, style: AppTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            VoraButton(
              label: actionLabel!,
              onPressed: onAction!,
              icon: Icons.add_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
