import '../constant/exports.dart';

class AppButton extends StatelessWidget {
  final String buttonText;
  final void Function()? onTapFunction;
  final bool isLoading;
  final Color? textColor;
  final Color? buttonColor;
  final double? radius;
  final double? fontSize;
  final Color? loaderColor;
  final Widget? iconWidget;
  final bool isRight;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.buttonText,
    this.onTapFunction,
    this.isLoading = false,
    this.textColor,
    this.buttonColor,
    this.radius,
    this.fontSize,
    this.loaderColor,
    this.iconWidget,
    this.isRight = false,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor ?? scheme.secondary,
        foregroundColor: textColor ?? scheme.onSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? 25.0),
        ),
        padding: padding,
        elevation: 2,
      ),
      onPressed: isLoading ? null : onTapFunction,
      child: Center(
        child: isLoading
            ? CircularProgressIndicator(color: loaderColor ?? scheme.onPrimary)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: iconWidget != null
                    ? isRight
                          ? [
                              Expanded(
                                child: Text(
                                  buttonText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor ?? Colors.black,
                                    fontSize: fontSize ?? 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              iconWidget!,
                            ]
                          : [
                              iconWidget!,
                              Expanded(
                                child: Text(
                                  buttonText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor ?? Colors.black,
                                    fontSize: fontSize ?? 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]
                    : [
                        Text(
                          buttonText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor ?? Colors.black,
                            fontSize: fontSize ?? 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
              ),
      ),
    );
  }
}
