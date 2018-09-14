#include "mupdf/fitz.h"
#include "svg-imp.h"

/* default page size */
#define DEF_WIDTH 12
#define DEF_HEIGHT 792
#define DEF_FONTSIZE 12

typedef struct svg_state_s svg_state;

struct svg_state_s
{
	fz_matrix transform;
	fz_stroke_state stroke;

	float viewport_w, viewport_h;
	float viewbox_w, viewbox_h, viewbox_size;
	float fontsize;

	float opacity;

	int fill_rule;
	int fill_is_set;
	float fill_color[3];
	float fill_opacity;

	int stroke_is_set;
	float stroke_color[3];
	float stroke_opacity;
};

static void svg_parse_common(fz_context *ctx, svg_document *doc, fz_xml *node, svg_state *state);
static void svg_run_element(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *root, const svg_state *state);

static void svg_fill(fz_context *ctx, fz_device *dev, svg_document *doc, fz_path *path, svg_state *state)
{
	float opacity = state->opacity * state->fill_opacity;
	fz_fill_path(ctx, dev, path, state->fill_rule, &state->transform, fz_device_rgb(ctx), state->fill_color, opacity);
}

static void svg_stroke(fz_context *ctx, fz_device *dev, svg_document *doc, fz_path *path, svg_state *state)
{
	float opacity = state->opacity * state->stroke_opacity;
	fz_stroke_path(ctx, dev, path, &state->stroke, &state->transform, fz_device_rgb(ctx), state->stroke_color, opacity);
}

static void svg_draw_path(fz_context *ctx, fz_device *dev, svg_document *doc, fz_path *path, svg_state *state)
{
	if (state->fill_is_set)
		svg_fill(ctx, dev, doc, path, state);
	if (state->stroke_is_set)
		svg_stroke(ctx, dev, doc, path, state);
}

/*
	We use the MAGIC number 0.551915 as a bezier subdivision to approximate
	a quarter circle arc. The reasons for this can be found here:
	http://mechanicalexpressions.com/explore/geometric-modeling/circle-spline-approximation.pdf
*/
static const float MAGIC_CIRCLE = 0.551915f;

static void approx_circle(fz_context *ctx, fz_path *path, float cx, float cy, float rx, float ry)
{
	float rxs = rx * MAGIC_CIRCLE;
	float rys = ry * MAGIC_CIRCLE;
	fz_moveto(ctx, path, cx, cy+ry);
	fz_curveto(ctx, path, cx + rxs, cy + ry, cx + rx, cy + rys, cx + rx, cy);
	fz_curveto(ctx, path, cx + rx, cy - rys, cx + rxs, cy - rys, cx, cy - ry);
	fz_curveto(ctx, path, cx - rxs, cy - ry, cx - rx, cy - rys, cx - rx, cy);
	fz_curveto(ctx, path, cx - rx, cy + rys, cx - rxs, cy + rys, cx, cy + ry);
	fz_closepath(ctx, path);
}

static void
svg_run_rect(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *node, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;

	char *x_att = fz_xml_att(node, "x");
	char *y_att = fz_xml_att(node, "y");
	char *w_att = fz_xml_att(node, "width");
	char *h_att = fz_xml_att(node, "height");
	char *rx_att = fz_xml_att(node, "rx");
	char *ry_att = fz_xml_att(node, "ry");

	float x = 0;
	float y = 0;
	float w = 0;
	float h = 0;
	float rx = 0;
	float ry = 0;

	fz_path *path;

	svg_parse_common(ctx, doc, node, &local_state);

	if (x_att) x = svg_parse_length(x_att, local_state.viewbox_w, local_state.fontsize);
	if (y_att) y = svg_parse_length(y_att, local_state.viewbox_h, local_state.fontsize);
	if (w_att) w = svg_parse_length(w_att, local_state.viewbox_w, local_state.fontsize);
	if (h_att) h = svg_parse_length(h_att, local_state.viewbox_h, local_state.fontsize);
	if (rx_att) rx = svg_parse_length(rx_att, local_state.viewbox_w, local_state.fontsize);
	if (ry_att) ry = svg_parse_length(ry_att, local_state.viewbox_h, local_state.fontsize);

	if (rx_att && !ry_att)
		ry = rx;
	if (ry_att && !rx_att)
		rx = ry;
	if (rx > w * 0.5)
		rx = w * 0.5;
	if (ry > h * 0.5)
		ry = h * 0.5;

	if (w <= 0 || h <= 0)
		return;

	path = fz_new_path(ctx);
	if (rx == 0 || ry == 0)
	{
		fz_moveto(ctx, path, x, y);
		fz_lineto(ctx, path, x + w, y);
		fz_lineto(ctx, path, x + w, y + h);
		fz_lineto(ctx, path, x, y + h);
	}
	else
	{
		float rxs = rx * MAGIC_CIRCLE;
		float rys = rx * MAGIC_CIRCLE;
		fz_moveto(ctx, path, x + w - rx, y);
		fz_curveto(ctx, path, x + w - rxs, y, x + w, y + rys, x + w, y + ry);
		fz_lineto(ctx, path, x + w, y + h - ry);
		fz_curveto(ctx, path, x + w, y + h - rys, x + w - rxs, y + h, x + w - rx, y + h);
		fz_lineto(ctx, path, x + rx, y + h);
		fz_curveto(ctx, path, x + rxs, y + h, x, y + h - rys, x, y + h - rx);
		fz_lineto(ctx, path, x, y + rx);
		fz_curveto(ctx, path, x, y + rxs, x + rxs, y, x + rx, y);
	}
	fz_closepath(ctx, path);

	svg_draw_path(ctx, dev, doc, path, &local_state);

	fz_drop_path(ctx, path);
}

static void
svg_run_circle(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *node, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;

	char *cx_att = fz_xml_att(node, "cx");
	char *cy_att = fz_xml_att(node, "cy");
	char *r_att = fz_xml_att(node, "r");

	float cx = 0;
	float cy = 0;
	float r = 0;
	fz_path *path;

	svg_parse_common(ctx, doc, node, &local_state);

	if (cx_att) cx = svg_parse_length(cx_att, local_state.viewbox_w, local_state.fontsize);
	if (cy_att) cy = svg_parse_length(cy_att, local_state.viewbox_h, local_state.fontsize);
	if (r_att) r = svg_parse_length(r_att, local_state.viewbox_size, 12);

	if (r <= 0)
		return;

	path = fz_new_path(ctx);
	approx_circle(ctx, path, cx, cy, r, r);
	svg_draw_path(ctx, dev, doc, path, &local_state);
	fz_drop_path(ctx, path);
}

static void
svg_run_ellipse(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *node, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;

	char *cx_att = fz_xml_att(node, "cx");
	char *cy_att = fz_xml_att(node, "cy");
	char *rx_att = fz_xml_att(node, "rx");
	char *ry_att = fz_xml_att(node, "ry");

	float cx = 0;
	float cy = 0;
	float rx = 0;
	float ry = 0;

	fz_path *path;

	svg_parse_common(ctx, doc, node, &local_state);

	if (cx_att) cx = svg_parse_length(cx_att, local_state.viewbox_w, local_state.fontsize);
	if (cy_att) cy = svg_parse_length(cy_att, local_state.viewbox_h, local_state.fontsize);
	if (rx_att) rx = svg_parse_length(rx_att, local_state.viewbox_w, local_state.fontsize);
	if (ry_att) ry = svg_parse_length(ry_att, local_state.viewbox_h, local_state.fontsize);

	if (rx <= 0 || ry <= 0)
		return;

	path = fz_new_path(ctx);
	approx_circle(ctx, path, cx, cy, rx, ry);
	svg_draw_path(ctx, dev, doc, path, &local_state);
	fz_drop_path(ctx, path);
}

static void
svg_run_line(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *node, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;

	char *x1_att = fz_xml_att(node, "x1");
	char *y1_att = fz_xml_att(node, "y1");
	char *x2_att = fz_xml_att(node, "x2");
	char *y2_att = fz_xml_att(node, "y2");

	float x1 = 0;
	float y1 = 0;
	float x2 = 0;
	float y2 = 0;

	svg_parse_common(ctx, doc, node, &local_state);

	if (x1_att) x1 = svg_parse_length(x1_att, local_state.viewbox_w, local_state.fontsize);
	if (y1_att) y1 = svg_parse_length(y1_att, local_state.viewbox_h, local_state.fontsize);
	if (x2_att) x2 = svg_parse_length(x2_att, local_state.viewbox_w, local_state.fontsize);
	if (y2_att) y2 = svg_parse_length(y2_att, local_state.viewbox_h, local_state.fontsize);

	if (local_state.stroke_is_set)
	{
		fz_path *path = fz_new_path(ctx);
		fz_moveto(ctx, path, x1, y1);
		fz_lineto(ctx, path, x2, y2);
		svg_stroke(ctx, dev, doc, path, &local_state);
		fz_drop_path(ctx, path);
	}
}

static fz_path *
svg_parse_polygon_imp(fz_context *ctx, svg_document *doc, fz_xml *node, int doclose)
{
	fz_path *path;

	const char *str = fz_xml_att(node, "points");
	float number;
	float args[2];
	int nargs;
	int isfirst;

	if (!str)
		return NULL;

	isfirst = 1;
	nargs = 0;

	path = fz_new_path(ctx);

	while (*str)
	{
		while (svg_is_whitespace_or_comma(*str))
			str ++;

		if (svg_is_digit(*str))
		{
			str = svg_lex_number(&number, str);
			args[nargs++] = number;
		}

		if (nargs == 2)
		{
			if (isfirst)
			{
				fz_moveto(ctx, path, args[0], args[1]);
				isfirst = 0;
			}
			else
			{
				fz_lineto(ctx, path, args[0], args[1]);
			}
			nargs = 0;
		}
	}

	return path;
}

static void
svg_run_polyline(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *node, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;

	svg_parse_common(ctx, doc, node, &local_state);

	if (local_state.stroke_is_set)
	{
		fz_path *path = svg_parse_polygon_imp(ctx, doc, node, 0);
		svg_stroke(ctx, dev, doc, path, &local_state);
		fz_drop_path(ctx, path);
	}
}

static void
svg_run_polygon(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *node, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;
	fz_path *path;

	svg_parse_common(ctx, doc, node, &local_state);

	path = svg_parse_polygon_imp(ctx, doc, node, 1);
	svg_draw_path(ctx, dev, doc, path, &local_state);
	fz_drop_path(ctx, path);
}

static fz_path *
svg_parse_path_data(fz_context *ctx, svg_document *doc, const char *str)
{
	fz_path *path = fz_new_path(ctx);

	fz_point p;
	float x1, y1, x2, y2;

	int cmd;
	float number;
	float args[6];
	int nargs;

	/* saved control point for smooth curves */
	int reset_smooth = 1;
	float smooth_x = 0.0;
	float smooth_y = 0.0;

	cmd = 0;
	nargs = 0;

	fz_try(ctx)
	{
		fz_moveto(ctx, path, 0.0, 0.0); /* for the case of opening 'm' */

		while (*str)
		{
			while (svg_is_whitespace_or_comma(*str))
				str ++;

			if (svg_is_digit(*str))
			{
				str = svg_lex_number(&number, str);
				if (nargs == 6)
					fz_throw(ctx, FZ_ERROR_GENERIC, "stack overflow in path data");
				args[nargs++] = number;
			}
			else if (svg_is_alpha(*str))
			{
				if (nargs != 0)
					fz_throw(ctx, FZ_ERROR_GENERIC, "syntax error in path data (wrong number of parameters to '%c')", cmd);
				cmd = *str++;
			}
			else if (*str == 0)
			{
				break;
			}
			else
			{
				fz_throw(ctx, FZ_ERROR_GENERIC, "syntax error in path data: '%c'", *str);
			}

			if (reset_smooth)
			{
				smooth_x = 0.0;
				smooth_y = 0.0;
			}

			reset_smooth = 1;

			switch (cmd)
			{
			case 'M':
				if (nargs == 2)
				{
					fz_moveto(ctx, path, args[0], args[1]);
					nargs = 0;
					cmd = 'L'; /* implicit lineto after */
				}
				break;

			case 'm':
				if (nargs == 2)
				{
					p = fz_currentpoint(ctx, path);
					fz_moveto(ctx, path, p.x + args[0], p.y + args[1]);
					nargs = 0;
					cmd = 'l'; /* implicit lineto after */
				}
				break;

			case 'Z':
			case 'z':
				if (nargs == 0)
				{
					fz_closepath(ctx, path);
				}
				break;

			case 'L':
				if (nargs == 2)
				{
					fz_lineto(ctx, path, args[0], args[1]);
					nargs = 0;
				}
				break;

			case 'l':
				if (nargs == 2)
				{
					p = fz_currentpoint(ctx, path);
					fz_lineto(ctx, path, p.x + args[0], p.y + args[1]);
					nargs = 0;
				}
				break;

			case 'H':
				if (nargs == 1)
				{
					p = fz_currentpoint(ctx, path);
					fz_lineto(ctx, path, args[0], p.y);
					nargs = 0;
				}
				break;

			case 'h':
				if (nargs == 1)
				{
					p = fz_currentpoint(ctx, path);
					fz_lineto(ctx, path, p.x + args[0], p.y);
					nargs = 0;
				}
				break;

			case 'V':
				if (nargs == 1)
				{
					p = fz_currentpoint(ctx, path);
					fz_lineto(ctx, path, p.x, args[0]);
					nargs = 0;
				}
				break;

			case 'v':
				if (nargs == 1)
				{
					p = fz_currentpoint(ctx, path);
					fz_lineto(ctx, path, p.x, p.y + args[0]);
					nargs = 0;
				}
				break;

			case 'C':
				reset_smooth = 0;
				if (nargs == 6)
				{
					fz_curveto(ctx, path, args[0], args[1], args[2], args[3], args[4], args[5]);
					smooth_x = args[4] - args[2];
					smooth_y = args[5] - args[3];
					nargs = 0;
				}
				break;

			case 'c':
				reset_smooth = 0;
				if (nargs == 6)
				{
					p = fz_currentpoint(ctx, path);
					fz_curveto(ctx, path,
						p.x + args[0], p.y + args[1],
						p.x + args[2], p.y + args[3],
						p.x + args[4], p.y + args[5]);
					smooth_x = args[4] - args[2];
					smooth_y = args[5] - args[3];
					nargs = 0;
				}
				break;

			case 'S':
				reset_smooth = 0;
				if (nargs == 4)
				{
					p = fz_currentpoint(ctx, path);
					fz_curveto(ctx, path,
							p.x + smooth_x, p.y + smooth_y,
							args[0], args[1],
							args[2], args[3]);
					smooth_x = args[2] - args[0];
					smooth_y = args[3] - args[1];
					nargs = 0;
				}
				break;

			case 's':
				reset_smooth = 0;
				if (nargs == 4)
				{
					p = fz_currentpoint(ctx, path);
					fz_curveto(ctx, path,
							p.x + smooth_x, p.y + smooth_y,
							p.x + args[0], p.y + args[1],
							p.x + args[2], p.y + args[3]);
					smooth_x = args[2] - args[0];
					smooth_y = args[3] - args[1];
					nargs = 0;
				}
				break;

			case 'Q':
				reset_smooth = 0;
				if (nargs == 4)
				{
					p = fz_currentpoint(ctx, path);
					x1 = args[0];
					y1 = args[1];
					x2 = args[2];
					y2 = args[3];
					fz_curveto(ctx, path,
							(p.x + 2 * x1) / 3, (p.y + 2 * y1) / 3,
							(x2 + 2 * x1) / 3, (y2 + 2 * y1) / 3,
							x2, y2);
					smooth_x = x2 - x1;
					smooth_y = y2 - y1;
					nargs = 0;
				}
				break;

			case 'q':
				reset_smooth = 0;
				if (nargs == 4)
				{
					p = fz_currentpoint(ctx, path);
					x1 = args[0] + p.x;
					y1 = args[1] + p.y;
					x2 = args[2] + p.x;
					y2 = args[3] + p.y;
					fz_curveto(ctx, path,
							(p.x + 2 * x1) / 3, (p.y + 2 * y1) / 3,
							(x2 + 2 * x1) / 3, (y2 + 2 * y1) / 3,
							x2, y2);
					smooth_x = x2 - x1;
					smooth_y = y2 - y1;
					nargs = 0;
				}
				break;

			case 'T':
				reset_smooth = 0;
				if (nargs == 4)
				{
					p = fz_currentpoint(ctx, path);
					x1 = p.x + smooth_x;
					y1 = p.y + smooth_y;
					x2 = args[0];
					y2 = args[1];
					fz_curveto(ctx, path,
							(p.x + 2 * x1) / 3, (p.y + 2 * y1) / 3,
							(x2 + 2 * x1) / 3, (y2 + 2 * y1) / 3,
							x2, y2);
					smooth_x = x2 - x1;
					smooth_y = y2 - y1;
					nargs = 0;
				}
				break;

			case 't':
				reset_smooth = 0;
				if (nargs == 4)
				{
					p = fz_currentpoint(ctx, path);
					x1 = p.x + smooth_x;
					y1 = p.y + smooth_y;
					x2 = args[0] + p.x;
					y2 = args[1] + p.y;
					fz_curveto(ctx, path,
							(p.x + 2 * x1) / 3, (p.y + 2 * y1) / 3,
							(x2 + 2 * x1) / 3, (y2 + 2 * y1) / 3,
							x2, y2);
					smooth_x = x2 - x1;
					smooth_y = y2 - y1;
					nargs = 0;
				}
				break;

			case 0:
				if (nargs != 0)
					fz_throw(ctx, FZ_ERROR_GENERIC, "path data must begin with a command");
				break;

			default:
				fz_throw(ctx, FZ_ERROR_GENERIC, "unrecognized command in path data: '%c'", cmd);
			}
		}
	}
	fz_catch(ctx)
	{
		fz_drop_path(ctx, path);
		fz_rethrow(ctx);
	}

	return path;
}

static void
svg_run_path(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *node, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;

	const char *d_att = fz_xml_att(node, "d");
	/* unused: char *path_length_att = fz_xml_att(node, "pathLength"); */

	svg_parse_common(ctx, doc, node, &local_state);

	if (d_att)
	{
		fz_path *path = svg_parse_path_data(ctx, doc, d_att);
		svg_draw_path(ctx, dev, doc, path, &local_state);
		fz_drop_path(ctx, path);
	}
}

/* svg, symbol, image, foreignObject establish new viewports */
void
svg_parse_viewport(fz_context *ctx, svg_document *doc, fz_xml *node, svg_state *state)
{
	//fz_matrix *transform = &state->transform;

	char *x_att = fz_xml_att(node, "x");
	char *y_att = fz_xml_att(node, "y");
	char *w_att = fz_xml_att(node, "width");
	char *h_att = fz_xml_att(node, "height");

	float x = 0;
	float y = 0;
	float w = state->viewport_w;
	float h = state->viewport_h;

	if (x_att) x = svg_parse_length(x_att, state->viewbox_w, state->fontsize);
	if (y_att) y = svg_parse_length(y_att, state->viewbox_h, state->fontsize);
	if (w_att) w = svg_parse_length(w_att, state->viewbox_w, state->fontsize);
	if (h_att) h = svg_parse_length(h_att, state->viewbox_h, state->fontsize);

	/* TODO: new transform */
	fz_warn(ctx, "push viewport: %g %g %g %g", x, y, w, h);

	state->viewport_w = w;
	state->viewport_h = h;
}

/* svg, symbol, image, foreignObject plus marker, pattern, view can use viewBox to set the transform */
void
svg_parse_viewbox(fz_context *ctx, svg_document *doc, fz_xml *node, svg_state *state)
{
	//fz_matrix *transform = &state->transform;
	//float port_w = state->viewport_w;
	//float port_h = state->viewport_h;
	float min_x, min_y, box_w, box_h;

	char *viewbox_att = fz_xml_att(node, "viewBox");
	if (viewbox_att)
	{
		sscanf(viewbox_att, "%g %g %g %g", &min_x, &min_y, &box_w, &box_h);

		/* scale and translate to fit [x y w h] to [0 0 viewport.w viewport.h] */
		fz_warn(ctx, "push viewbox: %g %g %g %g", min_x, min_y, box_w, box_h);
	}
}

/* parse transform and presentation attributes */
void
svg_parse_common(fz_context *ctx, svg_document *doc, fz_xml *node, svg_state *state)
{
	fz_stroke_state *stroke = &state->stroke;
	fz_matrix *transform = &state->transform;

	char *transform_att = fz_xml_att(node, "transform");

	char *font_size_att = fz_xml_att(node, "font-size");
	// TODO: all font stuff

	// TODO: clip, clip-path, clip-rule

	char *opacity_att = fz_xml_att(node, "opacity");

	char *fill_att = fz_xml_att(node, "fill");
	char *fill_rule_att = fz_xml_att(node, "fill-rule");
	char *fill_opacity_att = fz_xml_att(node, "fill-opacity");

	char *stroke_att = fz_xml_att(node, "stroke");
	char *stroke_opacity_att = fz_xml_att(node, "stroke-opacity");
	char *stroke_width_att = fz_xml_att(node, "stroke-width");
	char *stroke_linecap_att = fz_xml_att(node, "stroke-linecap");
	char *stroke_linejoin_att = fz_xml_att(node, "stroke-linejoin");
	char *stroke_miterlimit_att = fz_xml_att(node, "stroke-miterlimit");
	// TODO: stroke-dasharray, stroke-dashoffset

	// TODO: marker, marker-start, marker-mid, marker-end

	// TODO: overflow
	// TODO: mask

	if (transform_att)
	{
		svg_parse_transform(ctx, doc, transform_att, transform);
	}

	if (font_size_att)
	{
		state->fontsize = svg_parse_length(font_size_att, state->fontsize, state->fontsize);
	}

	if (opacity_att)
	{
		state->opacity = svg_parse_number(opacity_att, 0, 1, state->opacity);
	}

	if (fill_att)
	{
		if (!strcmp(fill_att, "none"))
		{
			state->fill_is_set = 0;
		}
		else
		{
			state->fill_is_set = 1;
			svg_parse_color(ctx, doc, fill_att, state->fill_color);
		}
	}

	if (fill_opacity_att)
		state->fill_opacity = svg_parse_number(fill_opacity_att, 0, 1, state->fill_opacity);

	if (fill_rule_att)
	{
		if (!strcmp(fill_rule_att, "nonzero"))
			state->fill_rule = 1;
		if (!strcmp(fill_rule_att, "evenodd"))
			state->fill_rule = 0;
	}

	if (stroke_att)
	{
		if (!strcmp(stroke_att, "none"))
		{
			state->stroke_is_set = 0;
		}
		else
		{
			state->stroke_is_set = 1;
			svg_parse_color(ctx, doc, stroke_att, state->stroke_color);
		}
	}

	if (stroke_opacity_att)
		state->stroke_opacity = svg_parse_number(stroke_opacity_att, 0, 1, state->stroke_opacity);

	if (stroke_width_att)
	{
		if (!strcmp(stroke_width_att, "inherit"))
			;
		else
			stroke->linewidth = svg_parse_length(stroke_width_att, state->viewbox_size, state->fontsize);
	}
	else
	{
		stroke->linewidth = 1;
	}

	if (stroke_linecap_att)
	{
		if (!strcmp(stroke_linecap_att, "butt"))
			stroke->start_cap = FZ_LINECAP_BUTT;
		if (!strcmp(stroke_linecap_att, "round"))
			stroke->start_cap = FZ_LINECAP_ROUND;
		if (!strcmp(stroke_linecap_att, "square"))
			stroke->start_cap = FZ_LINECAP_SQUARE;
	}
	else
	{
		stroke->start_cap = FZ_LINECAP_BUTT;
	}

	stroke->dash_cap = stroke->start_cap;
	stroke->end_cap = stroke->start_cap;

	if (stroke_linejoin_att)
	{
		if (!strcmp(stroke_linejoin_att, "miter"))
			stroke->linejoin = FZ_LINEJOIN_MITER;
		if (!strcmp(stroke_linejoin_att, "round"))
			stroke->linejoin = FZ_LINEJOIN_ROUND;
		if (!strcmp(stroke_linejoin_att, "bevel"))
			stroke->linejoin = FZ_LINEJOIN_BEVEL;
	}
	else
	{
		stroke->linejoin = FZ_LINEJOIN_MITER;
	}

	if (stroke_miterlimit_att)
	{
		if (!strcmp(stroke_miterlimit_att, "inherit"))
			;
		else
			stroke->miterlimit = svg_parse_length(stroke_miterlimit_att, state->viewbox_size, state->fontsize);
	}
	else
	{
		stroke->miterlimit = 4.0;
	}
}

static void
svg_run_svg(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *root, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;
	fz_xml *node;

	svg_parse_viewport(ctx, doc, root, &local_state);
	svg_parse_viewbox(ctx, doc, root, &local_state);
	svg_parse_common(ctx, doc, root, &local_state);

	for (node = fz_xml_down(root); node; node = fz_xml_next(node))
		svg_run_element(ctx, dev, doc, node, &local_state);
}

static void
svg_run_g(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *root, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;
	fz_xml *node;

	svg_parse_common(ctx, doc, root, &local_state);

	for (node = fz_xml_down(root); node; node = fz_xml_next(node))
		svg_run_element(ctx, dev, doc, node, &local_state);
}

static void
svg_run_use_symbol(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *use, fz_xml *symbol, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;
	fz_xml *node;

	svg_parse_viewport(ctx, doc, use, &local_state);
	svg_parse_viewbox(ctx, doc, use, &local_state);
	svg_parse_common(ctx, doc, use, &local_state);

	for (node = fz_xml_down(symbol); node; node = fz_xml_next(node))
		svg_run_element(ctx, dev, doc, node, &local_state);
}

static void
svg_run_use(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *root, const svg_state *inherit_state)
{
	svg_state local_state = *inherit_state;

	char *xlink_href_att = fz_xml_att(root, "xlink:href");
	char *x_att = fz_xml_att(root, "x");
	char *y_att = fz_xml_att(root, "y");

	float x = 0;
	float y = 0;

	svg_parse_common(ctx, doc, root, &local_state);
	if (x_att) x = svg_parse_length(x_att, local_state.viewbox_w, local_state.fontsize);
	if (y_att) y = svg_parse_length(y_att, local_state.viewbox_h, local_state.fontsize);

	fz_pre_translate(&local_state.transform, x, y);

	if (xlink_href_att && xlink_href_att[0] == '#')
	{
		fz_xml *linked = fz_tree_lookup(ctx, doc->idmap, xlink_href_att + 1);
		if (linked)
		{
			if (!strcmp(fz_xml_tag(linked), "symbol"))
				svg_run_use_symbol(ctx, dev, doc, root, linked, &local_state);
			else
				svg_run_element(ctx, dev, doc, linked, &local_state);
			return;
		}
	}

	fz_warn(ctx, "svg: cannot find linked symbol");
}

static void
svg_run_element(fz_context *ctx, fz_device *dev, svg_document *doc, fz_xml *root, const svg_state *state)
{
	char *tag = fz_xml_tag(root);

	if (!strcmp(tag, "svg"))
		svg_run_svg(ctx, dev, doc, root, state);

	else if (!strcmp(tag, "g"))
		svg_run_g(ctx, dev, doc, root, state);

	else if (!strcmp(tag, "title"))
		;
	else if (!strcmp(tag, "desc"))
		;

	else if (!strcmp(tag, "defs"))
		;
	else if (!strcmp(tag, "symbol"))
		;

	else if (!strcmp(tag, "use"))
		svg_run_use(ctx, dev, doc, root, state);

	else if (!strcmp(tag, "path"))
		svg_run_path(ctx, dev, doc, root, state);
	else if (!strcmp(tag, "rect"))
		svg_run_rect(ctx, dev, doc, root, state);
	else if (!strcmp(tag, "circle"))
		svg_run_circle(ctx, dev, doc, root, state);
	else if (!strcmp(tag, "ellipse"))
		svg_run_ellipse(ctx, dev, doc, root, state);
	else if (!strcmp(tag, "line"))
		svg_run_line(ctx, dev, doc, root, state);
	else if (!strcmp(tag, "polyline"))
		svg_run_polyline(ctx, dev, doc, root, state);
	else if (!strcmp(tag, "polygon"))
		svg_run_polygon(ctx, dev, doc, root, state);

#if 0
	else if (!strcmp(tag, "image"))
		svg_parse_image(ctx, doc, root);
	else if (!strcmp(tag, "text"))
		svg_run_text(ctx, dev, doc, root);
	else if (!strcmp(tag, "tspan"))
		svg_run_text_span(ctx, dev, doc, root);
	else if (!strcmp(tag, "tref"))
		svg_run_text_ref(ctx, dev, doc, root);
	else if (!strcmp(tag, "textPath"))
		svg_run_text_path(ctx, dev, doc, root);
#endif

	else
	{
		/* debug print unrecognized tags */
		fz_debug_xml(root, 0);
	}
}

void
svg_parse_document_bounds(fz_context *ctx, svg_document *doc, fz_xml *root)
{
	char *version_att;
	char *w_att;
	char *h_att;
	char *viewbox_att;
	int version;

	if (!fz_xml_is_tag(root, "svg"))
		fz_throw(ctx, FZ_ERROR_GENERIC, "expected svg element (found %s)", fz_xml_tag(root));

	version_att = fz_xml_att(root, "version");
	w_att = fz_xml_att(root, "width");
	h_att = fz_xml_att(root, "height");
	viewbox_att = fz_xml_att(root, "viewBox");

	version = 10;
	if (version_att)
		version = fz_atof(version_att) * 10;

	if (version > 12)
		fz_warn(ctx, "svg document version is newer than we support");

	/* If no width or height attributes, then guess from the viewbox */
	if (w_att == NULL && h_att == NULL && viewbox_att != NULL)
	{
		float min_x, min_y, box_w, box_h;
		sscanf(viewbox_att, "%g %g %g %g", &min_x, &min_y, &box_w, &box_h);
		doc->width = box_w;
		doc->height = box_h;
	}
	else
	{
		doc->width = DEF_WIDTH;
		if (w_att)
			doc->width = svg_parse_length(w_att, doc->width, DEF_FONTSIZE);

		doc->height = DEF_HEIGHT;
		if (h_att)
			doc->height = svg_parse_length(h_att, doc->height, DEF_FONTSIZE);
	}
}

void
svg_run_document(fz_context *ctx, svg_document *doc, fz_xml *root, fz_device *dev, const fz_matrix *ctm)
{
	svg_state state;

	svg_parse_document_bounds(ctx, doc, root);

	/* Initial graphics state */
	state.transform = *ctm;
	state.stroke = fz_default_stroke_state;

	state.viewport_w = DEF_WIDTH;
	state.viewport_h = DEF_HEIGHT;

	state.viewbox_w = DEF_WIDTH;
	state.viewbox_h = DEF_HEIGHT;
	state.viewbox_size = sqrtf(DEF_WIDTH*DEF_WIDTH + DEF_HEIGHT*DEF_HEIGHT) / sqrtf(2);

	state.fontsize = 12;

	state.opacity = 1;

	state.fill_rule = 0;

	state.fill_is_set = 1;
	state.fill_color[0] = 0;
	state.fill_color[1] = 0;
	state.fill_color[2] = 0;
	state.fill_opacity = 1;

	state.stroke_is_set = 0;
	state.stroke_color[0] = 0;
	state.stroke_color[1] = 0;
	state.stroke_color[2] = 0;
	state.stroke_opacity = 1;

	svg_run_svg(ctx, dev, doc, root, &state);
}
