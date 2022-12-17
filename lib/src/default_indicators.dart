import 'package:flutter/material.dart';

class DefaultNewPageProgressIndicator extends StatelessWidget {
  const DefaultNewPageProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

class DefaultNoItemsFoundIndicator extends StatelessWidget {
  const DefaultNoItemsFoundIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Text('No items found'),
      ),
    );
  }
}

class DefaultErrorIndicator extends StatelessWidget {
  const DefaultErrorIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Icon(
          Icons.error,
          size: 35,
        ),
      ),
    );
  }
}
