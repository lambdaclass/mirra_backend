defmodule SplinePath do
  @moduledoc """
  This module defines methods to generate a spline path out of a waypoint path
  """
alias BotManager.Math.Vector

  @segment_point_amount 15
  @tension 0
  @alpha 0.5

  def smooth_path(waypoints) when length(waypoints) < 3 do
    waypoints
  end

  def smooth_path(waypoints) do
    first_point = Enum.at(waypoints, 0)
    second_point = Enum.at(waypoints, 1)
    last_point = Enum.at(waypoints, -1)
    second_to_last_point = Enum.at(waypoints, -2)

    first_control_point = Vector.add(first_point, Vector.sub(first_point, second_point) |> Vector.normalize())
    last_control_point = Vector.add(last_point, Vector.sub(last_point, second_to_last_point) |> Vector.normalize())
    control_points = [first_control_point] ++ waypoints ++ [last_control_point]

    generate_spline_from_control_points(control_points) ++ [last_point]
  end

  defp generate_spline_from_control_points(control_points) do
    Enum.chunk_every(control_points, 4, 1, :discard)
    |> Enum.map(fn cps -> build_points_for_spline(cps) end)
    |> List.flatten()
  end

  # float t01 = pow(distance(p0, p1), alpha);
  # float t12 = pow(distance(p1, p2), alpha);
  # float t23 = pow(distance(p2, p3), alpha);

  # vec2 m1 = (1.0f - tension) *
  #     (p2 - p1 + t12 * (
  #         (p1 - p0) / t01 - (p2 - p0) / (t01 + t12)
  #       )
  #     );
  # vec2 m2 = (1.0f - tension) *
  #     (p2 - p1 + t12 * ((p3 - p2) / t23 - (p3 - p1) / (t12 + t23)));
  #
  # Segment segment;
  # segment.a = 2.0f * (p1 - p2) + m1 + m2;
  # segment.b = -3.0f * (p1 - p2) - m1 - m1 - m2;
  # segment.c = m1;
  # segment.d = p1;
  #
  # vec2 point = segment.a * t * t * t +
  #              segment.b * t * t +
  #              segment.c * t +
  #              segment.d;

  defp build_points_for_spline([p0, p1, p2, p3]) do
    t01 = :math.pow(Vector.distance(p0, p1), @alpha)
    t12 = :math.pow(Vector.distance(p1, p2), @alpha)
    t23 = :math.pow(Vector.distance(p2, p3), @alpha)
    
    m1 = Vector.sub(
      Vector.mult(Vector.sub(p1, p0), 1 / t01),
      Vector.mult(Vector.sub(p1, p0), 1 / (t01 + t12))
    )
    |> Vector.mult(t12)
    |> Vector.add(p2)
    |> Vector.sub(p1)
    |> Vector.mult(1.0 - @tension)

    m2 = Vector.sub(
      Vector.mult(Vector.sub(p3, p2), 1 / t23),
      Vector.mult(Vector.sub(p3, p1), 1 / (t12 + t23))
    )
    |> Vector.mult(t12)
    |> Vector.add(p2)
    |> Vector.sub(p1)
    |> Vector.mult(1.0 - @tension)

    a = Vector.sub(p1, p2)
    |> Vector.mult(2.0)
    |> Vector.add(m1)
    |> Vector.add(m2)

    b = Vector.sub(p1, p2)
    |> Vector.mult(-3.0)
    |> Vector.sub(m1)
    |> Vector.sub(m1)
    |> Vector.sub(m2)

    c = m1
    d = p1

    # last point will be the next part start so do not add it
    Enum.map(0..(@segment_point_amount - 1), fn segment_num -> 
      t = segment_num / @segment_point_amount

      d
      |> Vector.add(Vector.mult(c, t))
      |> Vector.add(Vector.mult(b, t * t))
      |> Vector.add(Vector.mult(a, t * t * t))
    end)
  end
end
