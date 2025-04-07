import * as pdfjsLib from "pdfjs-dist";

export default PdfPreview = {
  async mounted() {
    const canvas = this.el;
    const url = canvas.dataset.docurl
    
    pdfjsLib.GlobalWorkerOptions.workerSrc =
      "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.8.162/pdf.worker.min.js";

    var loadingTask = pdfjsLib.getDocument(url);
    loadingTask.promise.then(
      function (pdf) {
        // Fetch the first page
        var pageNumber = 1;
        pdf.getPage(pageNumber).then(function (page) {
          var scale = canvas.dataset.scale || 0.7;
          var viewport = page.getViewport({ scale: scale });

          // Prepare canvas using PDF page dimensions
          
          var context = canvas.getContext("2d");
          canvas.height = viewport.height;
          canvas.width = viewport.width;

          // Render PDF page into canvas context
          var renderContext = {
            canvasContext: context,
            viewport: viewport,
          };
          var renderTask = page.render(renderContext);
          renderTask.promise.then(function () {
            // console.log("Page rendered");
          });
        });
      },
      function (reason) {
        // PDF loading error
        console.error(reason);
      },
    );
  },
};
