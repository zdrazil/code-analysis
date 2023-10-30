// Based on https://github.com/adamtornhill/maat-scripts/blob/3f1afce263b193c41756af53a4cd8fc5553a3357/transform/crime-scene-hotspots.html

const margin = 10,
  outerDiameter = 960,
  innerDiameter = outerDiameter - margin - margin;

const x = d3.scale.linear().range([0, innerDiameter]);

const y = d3.scale.linear().range([0, innerDiameter]);

const color = d3.scale
  .linear()
  .domain([-1, 5])
  .range(["hsl(185,60%,99%)", "hsl(187,40%,70%)"])
  .interpolate(d3.interpolateHcl);

const pack = d3.layout
  .pack()
  .padding(2)
  .size([innerDiameter, innerDiameter])
  .value(function (d) {
    return d.size;
  });

const svg = d3
  .select("body")
  .append("svg")
  .attr("width", outerDiameter)
  .attr("height", outerDiameter)
  .append("g")
  .attr("transform", "translate(" + margin + "," + margin + ")");

d3.json("hotspots.json", function (error, root) {
  let focus = root,
    nodes = pack.nodes(root);

  const tooltip = d3
    .select("body")
    .append("div")
    .style("position", "absolute")
    .style("z-index", "10")
    .style("visibility", "hidden")
    .text("a simple tooltip")
    .attr("class", () => "label");

  svg
    .append("g")
    .selectAll("circle")
    .data(nodes)
    .enter()
    .append("circle")
    .attr("class", function (d) {
      return d.parent
        ? d.children
          ? "node"
          : "node node--leaf"
        : "node node--root";
    })
    .attr("transform", function (d) {
      return "translate(" + d.x + "," + d.y + ")";
    })
    .attr("r", function (d) {
      return d.r;
    })
    .style("fill", function (d) {
      return d.weight > 0.0
        ? "darkred"
        : d.children
        ? color(d.depth)
        : "WhiteSmoke";
    })
    .style("fill-opacity", function (d) {
      return d.weight;
    })
    .on("click", function (d) {
      return zoom(focus == d ? root : d);
    })
    .on("mouseover", function (d) {
      tooltip.text(d.name);
      return tooltip.style("visibility", "visible");
    })
    .on("mousemove", function () {
      return tooltip
        .style("top", d3.event.pageY - 10 + "px")
        .style("left", d3.event.pageX + 10 + "px");
    })
    .on("mouseout", function () {
      tooltip.text();

      return tooltip.style("visibility", "hidden");
    });

  svg
    .append("g")
    .selectAll("text")
    .data(nodes)
    .enter()
    .append("text")
    .attr("class", "label")
    .attr("transform", function (d) {
      return "translate(" + d.x + "," + d.y + ")";
    })
    .style("fill-opacity", function (d) {
      return d.parent === root ? 1 : 0;
    })
    .style("display", function (d) {
      return d.parent === root ? null : "none";
    })
    .text(function (d) {
      return d.name;
    });

  d3.select(window).on("click", function () {
    zoom(root);
  });

  function zoom(d, i) {
    const focus0 = focus;
    focus = d;

    const k = innerDiameter / d.r / 2;
    x.domain([d.x - d.r, d.x + d.r]);
    y.domain([d.y - d.r, d.y + d.r]);
    d3.event.stopPropagation();

    const transition = d3
      .selectAll("text,circle")
      .transition()
      .duration(d3.event.altKey ? 7500 : 750)
      .attr("transform", function (d) {
        return "translate(" + x(d.x) + "," + y(d.y) + ")";
      });

    transition.filter("circle").attr("r", function (d) {
      return k * d.r;
    });

    transition
      .filter("text")
      .filter(function (d) {
        return d.parent === focus || d.parent === focus0;
      })
      .style("fill-opacity", function (d) {
        return d.parent === focus ? 1 : 0;
      })
      .each("start", function (d) {
        if (d.parent === focus) this.style.display = "inline";
      })
      .each("end", function (d) {
        if (d.parent !== focus) this.style.display = "none";
      });
  }
});

d3.select(self.frameElement).style("height", outerDiameter + "px");
