# Collision detection

We are working with entities.

These entities can be of any of these types: Point, Line, Circle, Polygon.

Each entity has attributes, which can be mandatory or not:
- id: unique identifier
- shape: Point, Line, Circle, Polygon. To determine which collision algorithm to use
- radius: in the case of a circle
- speed: in case of movement
- direction: in case of movement
- name: unique name of the entity
- category: Player, Projectile, Obstacle. We use it to know when to check for collisions
- vertices: in case the entity is defined by points
- position: position of the entity on the map

For collision checking, we iterate through all entities searching for those that collide with the current one and return a list of all collisions.

The possible collision detection algorithms we handle are:

- Point-Circle: Collision occurs when the distance between the center of the circle and the point is less than the radius of the circle

insert-images

- Line-Circle: Collision occurs when the closest point on the line is inside the circle. It should be noted that when finding the nearest point, it should be within the segment.

insert-images

- Circle-Circle: Collision occurs when the distance between the centers of the circles is less than the sum of the radius

insert-images

- Circle-Polygon: Collision occurs when there is a collision between the circle and any of the segments of the polygon, or when the center of the circle is inside the polygon

insert-images

