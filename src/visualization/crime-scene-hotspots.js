// Based on https://github.com/adamtornhill/maat-scripts/blob/3f1afce263b193c41756af53a4cd8fc5553a3357/transform/crime-scene-hotspots.html

const margin = 10;
const outerDiameter = 960;
const innerDiameter = outerDiameter - margin - margin;

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
  .value((d) => d.size);

const svg = d3
  .select("body")
  .append("svg")
  .attr("width", outerDiameter)
  .attr("height", outerDiameter)
  .append("g")
  .attr("transform", `translate(${margin}, ${margin})`);
d3.json("hotspots.json", (error, root) => {
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
    .attr("class", (d) => {
      if (d.parent) {
        if (d.children) {
          return "node";
        } else {
          return "node node--leaf";
        }
      } else {
        return "node node--root";
      }
    })
    .attr("transform", (d) => `translate(${d.x}, ${d.y})`)
    .attr("r", (d) => d.r)
    .style("fill", (d) => {
      if (d.weight > 0.0) {
        return "darkred";
      } else if (d.children) {
        return color(d.depth);
      } else {
        return "WhiteSmoke";
      }
    })
    .style("fill-opacity", (d) => d.weight)
    .on("click", (d) => {
      zoom(focus == d ? root : d);
    })
    .on("mouseover", (d) => {
      tooltip.text(d.name).style("visibility", "visible");
    })
    .on("mousemove", () =>
      tooltip
        .style("top", d3.event.pageY - 10 + "px")
        .style("left", d3.event.pageX + 10 + "px"),
    )
    .on("mouseout", () => {
      tooltip.text().style("visibility", "hidden");
    });

  svg
    .append("g")
    .selectAll("text")
    .data(nodes)
    .enter()
    .append("text")
    .attr("class", "label")
    .attr("transform", (d) => `translate(${d.x}, ${d.y})`)
    .style("fill-opacity", (d) => (d.parent === root ? 1 : 0))
    .style("display", (d) => (d.parent === root ? null : "none"))
    .text((d) => d.name);

  d3.select(window).on("click", () => {
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
      .attr("transform", (d) => `translate(${x(d.x)}, ${y(d.y)})`);
    transition.filter("circle").attr("r", (d) => k * d.r);

    transition
      .filter("text")
      .filter((d) => d.parent === focus || d.parent === focus0)
      .style("fill-opacity", (d) => (d.parent === focus ? 1 : 0))
      .each("start", (d) => {
        if (d.parent === focus) {
          this.style.display = "inline";
        }
      })
      .each("end", (d) => {
        if (d.parent !== focus) {
          this.style.display = "none";
        }
      });
  }
});

d3.select(self.frameElement).style("height", outerDiameter + "px");
