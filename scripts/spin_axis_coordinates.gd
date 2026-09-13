extends RefCounted
class_name SpinAxisCoordinates

## Converts the equatorial coordinates of the spin pole to its position angle
## and inclination relative to the sky plane at the target position.
## PA is measured from celestial North towards East. Inclination is -90° on
## the observer-facing line of sight, 0° in the sky plane and +90° away.
static func equatorial_to_sky(
		pole_ra_deg: float,
		pole_dec_deg: float,
		target_ra_deg: float,
		target_dec_deg: float) -> Dictionary:
	var pole_ra := deg_to_rad(pole_ra_deg)
	var pole_dec := deg_to_rad(clampf(pole_dec_deg, -90.0, 90.0))
	var target_ra := deg_to_rad(target_ra_deg)
	var target_dec := deg_to_rad(clampf(target_dec_deg, -90.0, 90.0))
	var delta_ra := pole_ra - target_ra

	var pa := atan2(
		cos(pole_dec) * sin(delta_ra),
		cos(target_dec) * sin(pole_dec)
			- sin(target_dec) * cos(pole_dec) * cos(delta_ra))
	var angular_distance_cos := (
		cos(delta_ra) * cos(target_dec) * cos(pole_dec)
		+ sin(target_dec) * sin(pole_dec))
	var angular_distance := acos(clampf(angular_distance_cos, -1.0, 1.0))

	return {
		"pa": fposmod(rad_to_deg(pa), 360.0),
		"inclination": rad_to_deg(angular_distance) - 90.0,
	}

## Inverse transformation of equatorial_to_sky(). The current target
## coordinates are required because PA/inclination describe a tangent-plane
## direction at that position on the celestial sphere.
static func sky_to_equatorial(
		pa_deg: float,
		inclination_deg: float,
		target_ra_deg: float,
		target_dec_deg: float) -> Dictionary:
	var pa := deg_to_rad(fposmod(pa_deg, 360.0))
	var angular_distance := deg_to_rad(clampf(inclination_deg, -90.0, 90.0) + 90.0)
	var target_ra := deg_to_rad(target_ra_deg)
	var target_dec := deg_to_rad(clampf(target_dec_deg, -90.0, 90.0))

	var pole_dec := asin(clampf(
		sin(target_dec) * cos(angular_distance)
		+ cos(target_dec) * sin(angular_distance) * cos(pa),
		-1.0,
		1.0))
	var delta_ra := atan2(
		sin(pa) * sin(angular_distance) * cos(target_dec),
		cos(angular_distance) - sin(target_dec) * sin(pole_dec))
	var pole_ra := target_ra + delta_ra

	return {
		"ra": fposmod(rad_to_deg(pole_ra), 360.0),
		"dec": clampf(rad_to_deg(pole_dec), -90.0, 90.0),
	}
