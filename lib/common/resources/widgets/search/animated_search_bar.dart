import 'package:flutter/material.dart';

class AnimatedSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const AnimatedSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  bool _isExpanded = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _controller.clear();
        widget.onClear?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? MediaQuery.of(context).size.width - 32 : 56,
      height: 56,
      child: _isExpanded
          ? TextField(
              controller: _controller,
              autofocus: true,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            )
          : IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                shape: const CircleBorder(),
              ),
            ),
    );
  }
}