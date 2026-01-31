import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final bool readOnly;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 24,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          iconSize: size,
          icon: Icon(
            rating >= starIndex ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: readOnly
              ? null
              : () {
                  if (rating == starIndex) {
                    onRatingChanged(0); // reset rating se clicar na mesma estrela
                  } else {
                    onRatingChanged(starIndex);
                  }
                },
          tooltip: '$starIndex estrela${starIndex > 1 ? 's' : ''}',
        );
      }),
    );
  }
}

