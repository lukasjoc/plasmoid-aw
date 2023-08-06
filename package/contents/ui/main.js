function isQualifiedSeries(s) {
    return s > 0.0;
}

const baseURL = 'http://localhost:3343/hourly';

function getLatestHourlyEvents(heading, label, barChart, barModel) {
    const req = new XMLHttpRequest();

    req.onreadystatechange = function() {
        if (req.readyState !== XMLHttpRequest.DONE) {
            return;
        }
        if (req.status === 200) {
            const data = JSON.parse(req.responseText);

            const hours = Object.entries(data.hourly);
            const [start] = hours.find(([_, m]) => isQualifiedSeries(m));
            hours.reverse();
            const [current] = hours.find(([_, m]) => isQualifiedSeries(m));

            // Room for tinkering :)
            barChart.barWidth = Math.abs((barChart.width / current) - barChart.spacing);
            console.log("barchart: barWidth", barChart.barWidth)

            // Preparing all of the data for the barchart
            barModel.clear();
            console.log('barmodel: clear');
            for (let hour = start; hour <= current; hour++) {
                const usage = data.hourly[hour];
                const bar = { usageMinutes: usage > 60.0 ? 60 : usage };
                console.log('barmodel: append', JSON.stringify(bar));
                barModel.append(bar);
            }

            // Setting the text for the heading
            const accumulatedHours = Math.floor(data.accumulated / 60);
            const accumulatedMinutes = Math.round(data.accumulated % 60);
            const parts = [];
            if (accumulatedHours > 0) {
                parts.push(accumulatedHours + 'h');
            }
            if (accumulatedMinutes > 0) {
                parts.push(accumulatedMinutes + 'm');
            }
            heading.text = parts.join(' ');

            // Setting the text for the hour range
            const range = [];
            if (start !== current) {
                range.push(start, current);
                label.text = `(${range.join(' - ')})`;
            } else {
                label.text = '';
            }
        }
    };

    req.open('GET', baseURL);
    req.send();
}
